#!/bin/bash
# memory-bridge.sh - QMD ↔ OpenClaw 记忆联动桥接 v1
# 功能：
#   1. chat_memory.db 对话块 → memory.db 知识条目（自动提取关键对话）
#   2. memory.db 知识条目 → chat_memory.db（反向注入，让对话搜索能搜到知识库）
#   3. 健康检查 + 统计
# 用法：
#   ./memory-bridge.sh sync     双向同步
#   ./memory-bridge.sh forward  对话→知识库（提取重要对话）
#   ./memory-bridge.sh reverse  知识库→对话（注入知识到搜索索引）
#   ./memory-bridge.sh status   桥接状态检查
#   ./memory-bridge.sh fix      修复异常数据

set -euo pipefail

# ====== 路径配置 ======
WORKSPACE="/Users/seven/.openclaw/workspace"
CHAT_DB="$WORKSPACE/data/chat_memory.db"
KNOW_DB="$WORKSPACE/data/memory.db"
BRIDGE_META="$WORKSPACE/data/.bridge_meta.json"
LOG_PREFIX="[bridge]"

# ====== 工具函数 ======
log()  { echo "$LOG_PREFIX $*"; }
ok()   { echo "$LOG_PREFIX ✅ $*"; }
warn() { echo "$LOG_PREFIX ⚠️  $*"; }
err()  { echo "$LOG_PREFIX ❌ $*" >&2; }

ensure_dbs() {
  [ -f "$CHAT_DB" ]  || { err "chat_memory.db 不存在: $CHAT_DB"; return 1; }
  [ -f "$KNOW_DB" ]   || { err "memory.db 不存在: $KNOW_DB"; return 1; }
}

get_meta() {
  if [ -f "$BRIDGE_META" ]; then
    cat "$BRIDGE_META"
  else
    echo '{"last_forward_ts":0,"last_reverse_ts":0,"forward_count":0,"reverse_count":0}'
  fi
}

set_meta() {
  echo "$1" > "$BRIDGE_META"
}

# ====== 前向同步：对话 → 知识库 ======
forward_sync() {
  log "前向同步：提取重要对话存入知识库..."

  # 获取上次同步时间戳
  META=$(get_meta)
  LAST_TS=$(echo "$META" | python3 -c "import json,sys; print(json.load(sys.stdin).get('last_forward_ts',0))" 2>/dev/null || echo 0)

  # 从chunks表取上次同步之后的新增/更新的文本块
  export LAST_FW_TS="$LAST_TS"
  ACTUAL_COUNT=$(python3 <<'PYEOF'
import sqlite3, hashlib, json, os, time

CHAT_DB = os.environ.get("CHAT_DB_PATH", "/Users/seven/.openclaw/workspace/data/chat_memory.db")
KNOW_DB = os.environ.get("KNOW_DB_PATH", "/Users/seven/.openclaw/workspace/data/memory.db")
LAST_TS = int(os.environ.get("LAST_FW_TS", "0"))

src = sqlite3.connect(CHAT_DB)
dst = sqlite3.connect(KNOW_DB)

rows = src.execute("SELECT id, session_id, text, file_mtime FROM chunks WHERE file_mtime > ? ORDER BY file_mtime DESC LIMIT 200", (LAST_TS,)).fetchall()
count = 0

import re
PATTERN = re.compile(r'(方案|决策|结论|金额|客单价|转化率|成本|利润|风险|教训|计划|待办|TODO|记住|重要|确定|搞定|完成|失败|成功|缓存|token|费用|封号|违规|合规)', re.IGNORECASE)

for chunk_id, session_id, text, mtime in rows:
    if not text or len(text) < 20:
        continue
    if not PATTERN.search(text):
        continue
    title_match = re.search(r'[^。，！？\n]{4,30}', text[:200])
    title = title_match.group(0) if title_match else f"对话记录-{chunk_id}"
    text_hash = hashlib.md5(text.encode()).hexdigest()
    exists = dst.execute("SELECT count(*) FROM knowledge WHERE tags LIKE ?", (f'%hash:{text_hash}%',)).fetchone()[0]
    if exists == 0:
        safe_text = text.replace("'", "''")[:2000]
        try:
            dst.execute("INSERT INTO knowledge (category, title, content, source, tags, created_at) VALUES (?,?,?,?,?,datetime('now','localtime'))",
                        ("对话", title, safe_text, f"chat:{session_id}", f"hash:{text_hash}|chunk:{chunk_id}"))
            count += 1
        except Exception:
            pass

dst.commit()
src.close()
dst.close()
print(count)
PYEOF
)

  NOW_TS=$(date +%s)
  python3 -c "
import json
meta = json.load(open('$BRIDGE_META'))
meta['last_forward_ts'] = $NOW_TS
meta['forward_count'] = meta.get('forward_count', 0) + $ACTUAL_COUNT
json.dump(meta, open('$BRIDGE_META', 'w'), ensure_ascii=False)
" 2>/dev/null || true

  ok "前向同步完成，新增 ${ACTUAL_COUNT} 条重要对话到知识库"
}

# ====== 反向同步：知识库 → 对话搜索索引 ======
reverse_sync() {
  log "反向同步：知识库注入对话搜索索引..."

  # 从memory.db取出知识条目，写入chat_memory.db的chunks表
  KNOWLEDGE_COUNT=$(sqlite3 "$KNOW_DB" "SELECT count(*) FROM knowledge;" 2>/dev/null || echo 0)

  if [ "$KNOWLEDGE_COUNT" -eq 0 ]; then
    ok "知识库为空，无需同步"
    return 0
  fi

  SYNCED=$(python3 <<'PYEOF'
import sqlite3, hashlib, time, json, os

CHAT_DB = os.environ.get("CHAT_DB_PATH", "/Users/seven/.openclaw/workspace/data/chat_memory.db")
KNOW_DB = os.environ.get("KNOW_DB_PATH", "/Users/seven/.openclaw/workspace/data/memory.db")

src = sqlite3.connect(KNOW_DB)
dst = sqlite3.connect(CHAT_DB)

rows = src.execute("SELECT id, category, title, content, source FROM knowledge WHERE category != '对话'").fetchall()
synced = 0
now_ts = int(time.time())

for kid, cat, title, content, source in rows:
    if not title:
        continue
    text = f"[{cat}] {title}"
    if content:
        text += f" - {content[:1200]}"
    if source:
        text += f" ({source})"
    text_hash = hashlib.md5(text.encode()).hexdigest()
    exists = dst.execute("SELECT count(*) FROM chunks WHERE text_hash = ?", (text_hash,)).fetchone()[0]
    if exists == 0:
        try:
            dst.execute("INSERT OR IGNORE INTO chunks (session_id, text, msg_start, msg_end, file_mtime, text_hash) VALUES (?,?,?,?,?,?)",
                        ("knowledge_db", text, 0, 0, now_ts, text_hash))
            synced += 1
        except Exception:
            pass

dst.commit()
src.close()
dst.close()
print(synced)
PYEOF
)

  NOW_TS=$(date +%s)
  python3 -c "
import json
meta = json.load(open('$BRIDGE_META'))
meta['last_reverse_ts'] = $NOW_TS
meta['reverse_count'] = meta.get('reverse_count', 0) + $SYNCED
json.dump(meta, open('$BRIDGE_META', 'w'), ensure_ascii=False)
" 2>/dev/null || true

  ok "反向同步完成，${SYNCED} 条知识注入对话搜索索引"
}

# ====== 状态检查 ======
status_check() {
  echo "=========================================="
  echo "  记忆桥接状态"
  echo "=========================================="
  echo ""

  # chat_memory.db
  if [ -f "$CHAT_DB" ]; then
    CHUNKS=$(sqlite3 "$CHAT_DB" "SELECT count(*) FROM chunks;" 2>/dev/null || echo "?")
    VECTORS=$(sqlite3 "$CHAT_DB" "SELECT count(*) FROM vectors;" 2>/dev/null || echo "?")
    CHAT_KB_COUNT=$(sqlite3 "$CHAT_DB" "SELECT count(*) FROM chunks WHERE session_id = 'knowledge_db';" 2>/dev/null || echo 0)
    echo "💬 chat_memory.db:"
    echo "   对话块: $CHUNKS"
    echo "   向量数: $VECTORS"
    echo "   知识注入: $CHAT_KB_COUNT 条"
  else
    echo "💬 chat_memory.db: ❌ 不存在"
  fi
  echo ""

  # memory.db
  if [ -f "$KNOW_DB" ]; then
    K_TOTAL=$(sqlite3 "$KNOW_DB" "SELECT count(*) FROM knowledge;" 2>/dev/null || echo "?")
    K_DIALOG=$(sqlite3 "$KNOW_DB" "SELECT count(*) FROM knowledge WHERE category = '对话';" 2>/dev/null || echo 0)
    K_CATS=$(sqlite3 "$KNOW_DB" "SELECT category, count(*) FROM knowledge GROUP BY category ORDER BY count(*) DESC;" 2>/dev/null | sed 's/^/   /')
    echo "🧠 memory.db:"
    echo "   知识总数: $K_TOTAL"
    echo "   对话提取: $K_DIALOG 条"
    echo "   分类分布:"
    echo "$K_CATS"
  else
    echo "🧠 memory.db: ❌ 不存在"
  fi
  echo ""

  # 桥接元数据
  if [ -f "$BRIDGE_META" ]; then
    META=$(get_meta)
    FW=$(echo "$META" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"上次前向: {d.get('last_forward_ts',0)} | 累计{d.get('forward_count',0)}条\")" 2>/dev/null || echo "读取失败")
    RV=$(echo "$META" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"上次反向: {d.get('last_reverse_ts',0)} | 累计{d.get('reverse_count',0)}条\")" 2>/dev/null || echo "读取失败")
    echo "🔗 桥接记录:"
    echo "   $FW"
    echo "   $RV"
  else
    echo "🔗 桥接记录: 尚未运行过同步"
  fi
  echo ""
  echo "=========================================="
}

# ====== 修复 ======
fix_issues() {
  log "检查并修复异常数据..."

  FIXED=0

  # 1. 清理chat_memory.db中重复的text_hash
  if [ -f "$CHAT_DB" ]; then
    DUPES=$(sqlite3 "$CHAT_DB" "SELECT text_hash, count(*) as cnt FROM chunks GROUP BY text_hash HAVING cnt > 1;" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DUPES" -gt 0 ]; then
      log "清理 $DUPES 个重复text_hash..."
      sqlite3 "$CHAT_DB" "DELETE FROM chunks WHERE id NOT IN (SELECT MIN(id) FROM chunks GROUP BY text_hash);" 2>/dev/null
      FIXED=$((FIXED + DUPES))
    fi

    # 2. 清理没有对应chunk的向量
    ORPHAN_VEC=$(sqlite3 "$CHAT_DB" "SELECT count(*) FROM vectors WHERE id NOT IN (SELECT id FROM chunks);" 2>/dev/null || echo 0)
    if [ "$ORPHAN_VEC" -gt 0 ]; then
      log "清理 $ORPHAN_VEC 个孤立向量..."
      sqlite3 "$CHAT_DB" "DELETE FROM vectors WHERE id NOT IN (SELECT id FROM chunks);" 2>/dev/null
      FIXED=$((FIXED + ORPHAN_VEC))
    fi
  fi

  # 3. 确保memory.db的FTS索引同步
  if [ -f "$KNOW_DB" ]; then
    FTSCHECK=$(sqlite3 "$KNOW_DB" "SELECT count(*) FROM knowledge_fts;" 2>/dev/null || echo 0)
    KCOUNT=$(sqlite3 "$KNOW_DB" "SELECT count(*) FROM knowledge;" 2>/dev/null || echo 0)
    if [ "$FTSCHECK" -ne "$KCOUNT" ]; then
      log "修复FTS索引（$FTSCHECK/$KCOUNT）..."
      sqlite3 "$KNOW_DB" "INSERT OR IGNORE INTO knowledge_fts(rowid,category,title,content,source,tags,url) SELECT id,category,title,content,source,tags,url FROM knowledge WHERE id NOT IN (SELECT rowid FROM knowledge_fts);" 2>/dev/null
      FIXED=$((FIXED + 1))
    fi
  fi

  if [ "$FIXED" -gt 0 ]; then
    ok "修复完成，处理了 $FIXED 个问题"
  else
    ok "一切正常，无需修复"
  fi
}

# ====== 主入口 ======
main() {
  case "${1:-status}" in
    sync)
      ensure_dbs
      forward_sync
      echo ""
      reverse_sync
      # 同步后触发MEMORY.md更新
      bash "$WORKSPACE/data/sync_memory.sh" 2>/dev/null && ok "MEMORY.md 已更新"
      ;;
    forward)
      ensure_dbs
      forward_sync
      ;;
    reverse)
      ensure_dbs
      reverse_sync
      ;;
    status)
      status_check
      ;;
    fix)
      ensure_dbs
      fix_issues
      ;;
    *)
      echo "用法: $0 {sync|forward|reverse|status|fix}"
      echo ""
      echo "  sync     双向同步（对话→知识库 + 知识库→对话搜索）"
      echo "  forward  对话→知识库（提取重要对话存入知识库）"
      echo "  reverse  知识库→对话（注入知识到搜索索引）"
      echo "  status   查看桥接状态"
      echo "  fix      修复异常数据"
      exit 1
      ;;
  esac
}

main "$@"
