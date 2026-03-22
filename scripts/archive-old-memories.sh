#!/bin/bash
# OpenClaw 旧记忆自动归档脚本
# 目的：减少移动端加载时的数据量

MEMORY_DIR="/Users/seven/clawd/memory"
ARCHIVE_DIR="/Users/seven/clawd/memory/archive"
EVOLUTION_DIR="/Users/seven/clawd/evolution"

echo "🗄️  OpenClaw 记忆归档工具"
echo "=========================="

# 创建归档目录
mkdir -p "$ARCHIVE_DIR"

# 1. 归档3天前的记忆文件
find "$MEMORY_DIR" -name "2026-*.md" -type f -mtime +3 | while read file; do
    filename=$(basename "$file")
    echo "📦 归档: $filename"
    mv "$file" "$ARCHIVE_DIR/"
done

# 2. 压缩knowledge-index.md（保留最近20条）
if [ -f "$MEMORY_DIR/knowledge-index.md" ]; then
    total_lines=$(wc -l < "$MEMORY_DIR/knowledge-index.md")
    if [ "$total_lines" -gt 800 ]; then
        echo "📚 知识索引过大 ($total_lines 行)，创建精简版..."
        
        # 保留文件头和最近条目
        head -20 "$MEMORY_DIR/knowledge-index.md" > "$MEMORY_DIR/knowledge-index-recent.md"
        echo -e "\n... (省略旧条目，共 $total_lines 行) ...\n" >> "$MEMORY_DIR/knowledge-index-recent.md"
        
        # 保留最近20条知识条目
        grep "^## " "$MEMORY_DIR/knowledge-index.md" | tail -20 >> "$MEMORY_DIR/knowledge-index-recent.md"
        
        # 备份原文件
        mv "$MEMORY_DIR/knowledge-index.md" "$ARCHIVE_DIR/knowledge-index-$(date +%Y%m%d).md"
        mv "$MEMORY_DIR/knowledge-index-recent.md" "$MEMORY_DIR/knowledge-index.md"
        
        echo "✅ 知识索引已精简"
    fi
fi

# 3. 清理evolution目录中旧的研究文件
find "$EVOLUTION_DIR" -name "research-*.md" -type f -mtime +7 | while read file; do
    filename=$(basename "$file")
    echo "📦 归档研究文件: $filename"
    mv "$file" "$ARCHIVE_DIR/"
done

echo ""
echo "✅ 归档完成"
echo "📊 当前内存文件大小:"
du -sh "$MEMORY_DIR"/* 2>/dev/null | sort -hr | head -10
echo ""
echo "📦 归档目录大小:"
du -sh "$ARCHIVE_DIR" 2>/dev/null || echo "  暂无归档"
