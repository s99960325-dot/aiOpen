#!/bin/bash
# pre_compact.sh - 压缩前自动保存对话状态
# 由agent在压缩前调用

STATE_FILE="/Users/seven/.openclaw/workspace/memory/conversation-state.md"
PRECOMPACT_FILE="/Users/seven/.openclaw/workspace/memory/conversation-pre-compact.md"

# 确保 memory 目录存在
mkdir -p /Users/seven/.openclaw/workspace/memory/

# 如果pre-compact文件已存在，备份旧的
if [ -f "$PRECOMPACT_FILE" ]; then
  cp "$PRECOMPACT_FILE" "${PRECOMPACT_FILE}.bak"
fi

echo "Pre-compact state ready. Agent should update conversation-state.md and conversation-pre-compact.md before compaction."
