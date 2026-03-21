#!/bin/bash
# 对话自动存档脚本 v3
# 修复：去掉10分钟时间限制，改用索引文件跟踪已归档session
# 功能：解析session文件 → 存SQLite向量索引 → 写md备份
# 用法：每15分钟cron自动跑一次

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB="$SCRIPT_DIR/chat_memory.db"
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
TODAY=$(date +%Y-%m-%d)
ARCHIVE_FILE="$ARCHIVE_DIR/$TODAY.md"
PYTHON=""

# Python环境（优先venv）
if [ -f "$SCRIPT_DIR/.venv/bin/python3" ]; then
    PYTHON="$SCRIPT_DIR/.venv/bin/python3"
else
    PYTHON=$(which python3 2>/dev/null || echo "")
fi

mkdir -p "$ARCHIVE_DIR"

echo "[$(date '+%H:%M:%S')] 📖 对话存档开始..."

# ============ 第一部分：向量索引更新 ============
if [ -n "$PYTHON" ]; then
    if $PYTHON -c "import sentence_transformers, numpy" 2>/dev/null; then
        echo "  🧠 更新向量索引..."
        cd "$SCRIPT_DIR" && $PYTHON chat_search.py build 2>&1
    else
        echo "  ⚠️ Python依赖未就绪，跳过向量索引"
    fi
else
    echo "  ⚠️ 未找到Python，跳过向量索引"
fi

# ============ 第二部分：md对话归档 ============
echo "  📝 开始md归档..."

# 记录已归档session的索引文件（不依赖当日归档文件）
ARCHIVED_INDEX="$ARCHIVE_DIR/.archived_sessions.txt"
[ -f "$ARCHIVED_INDEX" ] || touch "$ARCHIVED_INDEX"

TODAY_START=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s" 2>/dev/null || date -d "$TODAY" "+%s" 2>/dev/null)
FOUND=0

# 创建归档文件头
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "# 对话归档 - $TODAY" > "$ARCHIVE_FILE"
    echo "" >> "$ARCHIVE_FILE"
    echo "自动生成，每次对话后更新。" >> "$ARCHIVE_FILE"
fi

for f in "$SESSIONS_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    [[ "$f" == *".reset."* || "$f" == *".deleted."* ]] && continue

    SESSION_ID=$(basename "$f" .jsonl)
    SESSION_SHORT=$(echo "$SESSION_ID" | cut -c1-12)

    # 检查是否已归档（通过索引文件）
    grep -q "^${SESSION_SHORT}$" "$ARCHIVED_INDEX" 2>/dev/null && continue

    # 用Python提取今天的消息
    EXTRACTED=$($PYTHON -c "
import json, sys, datetime

fpath = sys.argv[1]
today_start = $TODAY_START
messages = []

try:
    with open(fpath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                entry = json.loads(line)
                if entry.get('type') != 'message': continue
                msg = entry.get('message', {})
                role = msg.get('role', '')
                if role not in ('user', 'assistant'): continue
                ts = msg.get('ts', 0) or entry.get('ts', 0)
                if ts > 0 and ts < today_start: continue
                content = msg.get('content', '')
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    parts = [p.get('text', '') for p in content if isinstance(p, dict) and p.get('type') == 'text']
                    text = '\n'.join(parts)
                else:
                    continue
                if not text.strip(): continue
                time_str = datetime.datetime.fromtimestamp(ts).strftime('%H:%M') if ts > 0 else ''
                prefix = '👤' if role == 'user' else '🤖'
                text = text.strip()[:2000]
                messages.append(f'{time_str} {prefix} {text}')
            except: pass
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(0)

for m in messages:
    print(m)
" "$f" 2>&1)

    # 标记为已处理（无论是否有今天的新消息）
    echo "$SESSION_SHORT" >> "$ARCHIVED_INDEX"

    [ -z "$EXTRACTED" ] && continue

    # 写入归档
    echo "" >> "$ARCHIVE_FILE"
    echo "---" >> "$ARCHIVE_FILE"
    echo "" >> "$ARCHIVE_FILE"
    echo "## Session: $SESSION_SHORT ($TODAY)" >> "$ARCHIVE_FILE"
    echo "" >> "$ARCHIVE_FILE"
    echo "$EXTRACTED" >> "$ARCHIVE_FILE"

    echo "  ✅ 归档 $SESSION_SHORT"
    FOUND=$((FOUND + 1))
done

if [ "$FOUND" -eq 0 ]; then
    echo "  ℹ️ 没有新对话需要归档"
fi

# 清理30天前的归档
find "$ARCHIVE_DIR" -name "*.md" -mtime +30 -delete 2>/dev/null

echo "[$(date '+%H:%M:%S')] ✅ 存档完成（索引+归档+清理）"
