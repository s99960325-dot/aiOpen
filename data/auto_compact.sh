#!/bin/bash
# 自动压缩准备脚本 - 会话接近200K时自动保护记忆
# 由Cron每15分钟调用

# 动态获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAWD_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$CLAWD_DIR/memory"
LOG="$CLAWD_DIR/memory/compact.log"
THRESHOLD=160000  # 160K时触发

# 估算函数：基于memory目录的Markdown文件大小估算token数
# 中文环境下约 1 token = 1.5-2 字符，保守按 1.5 计算
estimate_tokens_by_filesize() {
    local total_bytes=0
    # 计算memory目录下所有md文件的大小
    for file in "$MEMORY_DIR"/*.md; do
        if [ -f "$file" ]; then
            local size=$(wc -c < "$file" 2>/dev/null)
            total_bytes=$((total_bytes + size))
        fi
    done
    
    # 保守估算：每1.5字节算1个token，再加上基础开销
    local estimated=$((total_bytes / 15 * 10))  # 等同于 total_bytes / 1.5
    local base_overhead=5000  # 系统消息和上下文的固定开销
    echo $((estimated + base_overhead))
}

# 尝试从Kimi CLI日志获取token（如果可用）
get_tokens_from_kimi_logs() {
    local kimilog="/tmp/kimi-cli.log"
    local last_tokens=0
    
    # 检查Kimi日志文件
    if [ -f "$kimilog" ]; then
        # 尝试从日志中提取最近的token使用信息
        last_tokens=$(grep -oE 'total_tokens":[[:space:]]*[0-9]+' "$kimilog" 2>/dev/null | tail -1 | grep -oE '[0-9]+')
    fi
    
    # 检查openclaw gateway日志
    local gatewaylog="$HOME/.openclaw/logs/gateway.log"
    if [ -z "$last_tokens" ] && [ -f "$gatewaylog" ]; then
        # 尝试从gateway日志中提取token信息（如果有的话）
        last_tokens=$(grep -oE 'tokens[[:space:]]*[=:][[:space:]]*[0-9]+' "$gatewaylog" 2>/dev/null | tail -1 | grep -oE '[0-9]+')
    fi
    
    echo "$last_tokens"
}

# 主逻辑：获取当前会话token数
input_tokens=0

# 方法1：尝试使用 openclaw 命令（国际版）
if command -v openclaw &>/dev/null; then
    token_info=$(openclaw sessions --json --active 30 2>/dev/null)
    if [ -n "$token_info" ]; then
        input_tokens=$(echo "$token_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    sessions = data.get('sessions', [])
    if sessions:
        # 取最近更新的direct会话
        main = max([s for s in sessions if s.get('kind') == 'direct'], key=lambda s: s.get('updatedAt', 0))
        print(main.get('inputTokens', 0))
    else:
        print(0)
except:
    print(0)
" 2>/dev/null)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 通过 openclaw 获取token: $input_tokens" >> "$LOG"
    fi
fi

# 方法2：如果openclaw-cn没有结果，尝试从日志获取
if [ -z "$input_tokens" ] || [ "$input_tokens" -eq 0 ]; then
    input_tokens=$(get_tokens_from_kimi_logs)
    if [ -n "$input_tokens" ] && [ "$input_tokens" -gt 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 通过日志获取token: $input_tokens" >> "$LOG"
    fi
fi

# 方法3：如果都失败，使用文件大小估算
if [ -z "$input_tokens" ] || [ "$input_tokens" -eq 0 ]; then
    input_tokens=$(estimate_tokens_by_filesize)
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 通过文件大小估算token: $input_tokens" >> "$LOG"
fi

# 最终检查
if [ -z "$input_tokens" ] || [ "$input_tokens" -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 无法获取有效token信息" >> "$LOG"
    exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 当前估算token数: $input_tokens / 阈值: $THRESHOLD" >> "$LOG"

# 检查是否已经标记过
if [ -f "$MEMORY_DIR/compact-flag.txt" ]; then
    # 已经标记过，等待处理
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
