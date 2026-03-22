#!/bin/bash
# 全量导入历史会话到QMD索引
# 一次性执行，把所有session文件导成md放入memory目录

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
QMD_DIR="$HOME/.openclaw/workspace/memory/history"
mkdir -p "$QMD_DIR"

PYTHON=""
# 动态获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAWD_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$CLAWD_DIR/data/.venv/bin/python3" ]; then
    PYTHON="$CLAWD_DIR/data/.venv/bin/python3"
else
    PYTHON=$(which python3 2>/dev/null || echo "")
fi

if [ -z "$PYTHON" ]; then
  echo "❌ 未找到Python"
  exit 1
fi

echo "📖 开始全量导入历史会话..."

COUNT=0
for f in "$SESSIONS_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    [[ "$f" == *".reset."* || "$f" == *".deleted."* ]] && continue

    SESSION_ID=$(basename "$f" .jsonl)
    SESSION_SHORT=$(echo "$SESSION_ID" | cut -c1-12)
    OUTFILE="$QMD_DIR/${SESSION_SHORT}.md"

    # 跳过已处理的
    [ -f "$OUTFILE" ] && continue

    # 提取所有消息
    EXTRACTED=$($PYTHON -c "
import json, sys, datetime

fpath = sys.argv[1]
messages = []
session_start = None
session_end = None

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
                if ts > 0:
                    if session_start is None or ts < session_start:
                        session_start = ts
                    if session_end is None or ts > session_end:
                        session_end = ts
                content = msg.get('content', '')
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    parts = [p.get('text', '') for p in content if isinstance(p, dict) and p.get('type') == 'text']
                    text = '\n'.join(parts)
                else:
                    continue
                if not text.strip(): continue
                time_str = datetime.datetime.fromtimestamp(ts).strftime('%m-%d %H:%M') if ts > 0 else ''
                prefix = '用户' if role == 'user' else '军师'
                text = text.strip()[:3000]
                messages.append(f'{time_str} [{prefix}]: {text}')
            except: pass
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)

if not messages:
    sys.exit(0)

# 输出时间范围
if session_start and session_end:
    start_str = datetime.datetime.fromtimestamp(session_start).strftime('%Y-%m-%d %H:%M')
    end_str = datetime.datetime.fromtimestamp(session_end).strftime('%Y-%m-%d %H:%M')
    print(f'时间: {start_str} ~ {end_str}')
print(f'消息数: {len(messages)}')
print()
for m in messages:
    print(m)
" "$f" 2>&1)

    if [ -z "$EXTRACTED" ] || [ ${#EXTRACTED} -lt 50 ]; then
        continue
    fi

    # 写入文件
    echo "# 历史会话 $SESSION_SHORT" > "$OUTFILE"
    echo "" >> "$OUTFILE"
    echo "$EXTRACTED" >> "$OUTFILE"

    # 控制单文件大小，超过100KB截断
    size=$(wc -c < "$OUTFILE" 2>/dev/null)
    if [ "$size" -gt 102400 ]; then
        # 保留头部+尾部
        head -100 "$OUTFILE" > "${OUTFILE}.tmp"
        echo "" >> "${OUTFILE}.tmp"
        echo "... (中间省略，原文过长) ..." >> "${OUTFILE}.tmp"
        echo "" >> "${OUTFILE}.tmp"
        tail -100 "$OUTFILE" >> "${OUTFILE}.tmp"
        mv "${OUTFILE}.tmp" "$OUTFILE"
    fi

    COUNT=$((COUNT + 1))
    size=$(wc -c < "$OUTFILE")
    echo "  ✅ $SESSION_SHORT (${size} bytes)"
done

echo ""
echo "=== 导入完成：$COUNT 个会话 ==="

# 更新QMD索引
echo ""
echo "🔄 更新QMD索引..."
qmd update 2>&1
echo ""
echo "🧠 生成向量..."
QMD_EMBED_MODEL="hf:Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-Q8_0.gguf" qmd embed 2>&1
echo ""
echo "✅ 全部完成"
