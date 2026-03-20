#!/bin/bash
# SQLite → MEMORY.md 同步脚本 v5
# 轻量版：固定模板 + 最近20条 + 同步时间戳
# 详细数据用 query.sh 查SQLite，不塞进MEMORY.md
# 每6小时cron触发

set -euo pipefail

DB="/Users/seven/.openclaw/workspace/data/memory.db"
WORKSPACE="/Users/seven/.openclaw/workspace"
MEMORY_MD="$WORKSPACE/MEMORY.md"
HEADER_FILE="$WORKSPACE/MEMORY.md.header"
MEMORY_DIR="$WORKSPACE/memory"
TODAY=$(date +%Y-%m-%d)
DAILY_MD="$MEMORY_DIR/$TODAY.md"

mkdir -p "$MEMORY_DIR"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# ========== 1. 固定头部 ==========
cat "$HEADER_FILE" > "$TMP"

# ========== 2. 最近20条知识（摘要） ==========
echo "### 最近更新" >> "$TMP"
sqlite3 -separator '|' "$DB" "
SELECT category, title, substr(content,1,80), source
FROM knowledge ORDER BY rowid DESC LIMIT 20
" | while IFS='|' read -r cat title content source; do
  t=$(echo "$title" | sed 's/[][]//g')
  line="- [$cat] $t"
  [ -n "$content" ] && line="$line: ${content}..."
  [ -n "$source" ] && line="$line ($source)"
  echo "$line" >> "$TMP"
done
echo "" >> "$TMP"

# ========== 3. 快速统计 ==========
echo "### 数据统计" >> "$TMP"
sqlite3 "$DB" "
SELECT '知识: ' || count(*) FROM knowledge
UNION ALL SELECT '案例: ' || count(*) FROM cases
UNION ALL SELECT '法律: ' || count(*) FROM laws
UNION ALL SELECT '人脉: ' || count(*) FROM people
UNION ALL SELECT '项目: ' || count(*) FROM projects
" | sed 's/^/- /' >> "$TMP"
echo "- 详细查询: \`data/query.sh <关键词>\`" >> "$TMP"
echo "" >> "$TMP"

echo "> 同步: $(date '+%Y-%m-%d %H:%M:%S %Z') | 源: data/memory.db" >> "$TMP"

if ! diff -q "$MEMORY_MD" "$TMP" > /dev/null 2>&1; then
  cp "$TMP" "$MEMORY_MD"
  echo "[sync] MEMORY.md updated"
else
  echo "[sync] MEMORY.md unchanged"
fi

# ========== 4. 今日新增到 daily log ==========
TOTAL=0
for t in knowledge cases laws people projects; do
  n=$(sqlite3 "$DB" "SELECT count(*) FROM $t WHERE date(created_at) = '$TODAY'" 2>/dev/null || echo 0)
  TOTAL=$((TOTAL + n))
done

if [ "$TOTAL" -gt 0 ]; then
  [ ! -f "$DAILY_MD" ] && { echo "# $TODAY - 记忆同步日志"; echo ""; } > "$DAILY_MD"

  K=$(sqlite3 -separator '|' "$DB" "
    SELECT category, title, substr(content,1,200), source
    FROM knowledge WHERE date(created_at) = '$TODAY' ORDER BY rowid
  " 2>/dev/null)
  if [ -n "$K" ]; then
    echo "## 新增知识 ($(date '+%H:%M'))" >> "$DAILY_MD"
    echo "$K" | while IFS='|' read -r c t cnt s; do
      echo "- **[$c] $t**: ${cnt}$( [ -n "$s" ] && echo " ($s)")" >> "$DAILY_MD"
    done
    echo "" >> "$DAILY_MD"
  fi

  C=$(sqlite3 -separator '|' "$DB" "
    SELECT name, type, description FROM cases WHERE date(created_at) = '$TODAY'
  " 2>/dev/null)
  if [ -n "$C" ]; then
    echo "## 新增案例" >> "$DAILY_MD"
    echo "$C" | while IFS='|' read -r n t d; do
      echo "- **$n** [$t]: $d" >> "$DAILY_MD"
    done
    echo "" >> "$DAILY_MD"
  fi

  echo "[sync] $DAILY_MD updated ($TOTAL new)"
else
  echo "[sync] No new entries today"
fi

echo "[sync] Done."
