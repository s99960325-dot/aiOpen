#!/bin/bash
# 自动压缩准备脚本 - 会话接近200K时自动保护记忆
# 由Cron每15分钟调用

CLAWD_DIR="/Users/seven/clawd"
MEMORY_DIR="$CLAWD_DIR/memory"
LOG="$CLAWD_DIR/memory/compact.log"
THRESHOLD=160000  # 160K时触发

# 获取当前主会话token数
token_info=$(openclaw-cn sessions --json --active 30 2>/dev/null)
if [ -z "$token_info" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - 无法获取session信息" >> "$LOG"
  exit 0
fi

# 提取主会话(totalTokens最大的)的inputTokens
input_tokens=$(echo "$token_info" | python3 -c "
import json, sys
data = json.load(sys.stdin)
sessions = data.get('sessions', [])
if not sessions:
    print(0)
    sys.exit(0)
# 取最近更新的direct会话
main = max([s for s in sessions if s.get('kind') == 'direct'], key=lambda s: s.get('updatedAt', 0))
print(main.get('inputTokens', 0))
" 2>/dev/null)

if [ -z "$input_tokens" ] || [ "$input_tokens" -eq 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - 无活跃会话" >> "$LOG"
  exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 当前inputTokens: $input_tokens / 阈值: $THRESHOLD" >> "$LOG"

# 检查是否已经标记过
if [ -f "$MEMORY_DIR/compact-flag.txt" ]; then
  # 已经标记过，检查是否已压缩（compact-flag.txt被删除=已压缩）
  echo "$(date '+%Y-%m-%d %H:%M:%S') - 已标记待压缩，等待处理" >> "$LOG"
  exit 0
fi

if [ "$input_tokens" -lt "$THRESHOLD" ]; then
  exit 0
fi

# === 超过阈值，执行记忆保护 ===
echo "$(date '+%Y-%m-%d %H:%M:%S') - ⚠️ 接近上限(${input_tokens})，开始记忆保护" >> "$LOG"

# 1. 标记需要压缩
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$MEMORY_DIR/compact-flag.txt"

# 2. 同步SQLite知识到md文件（确保最新数据可被QMD索引）
if [ -x "$CLAWD_DIR/data/sync_memory.sh" ]; then
  bash "$CLAWD_DIR/data/sync_memory.sh" >> "$LOG" 2>&1
fi

# 3. 重新索引QMD
qmd update >> "$LOG" 2>&1
qmd embed >> "$LOG" 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ 记忆保护完成" >> "$LOG"
