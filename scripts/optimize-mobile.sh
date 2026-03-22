#!/bin/bash
# OpenClaw 移动端加载优化 - 一键执行脚本
# 执行所有优化步骤，提升移动端加载速度

set -e

CLAWD_DIR="/Users/seven/clawd"
SCRIPTS_DIR="$CLAWD_DIR/scripts"

echo "🚀 OpenClaw 移动端加载优化"
echo "============================"
echo ""

# 1. 检查文件
echo "📋 检查优化文件..."
files=("$CLAWD_DIR/monitor-mobile.js" "$CLAWD_DIR/monitor-sw.js" "$CLAWD_DIR/config/mobile-light.json")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $(basename $file)"
    else
        echo "  ❌ $(basename $file) 不存在"
        exit 1
    fi
done
echo ""

# 2. 创建归档目录
echo "📁 创建归档目录..."
mkdir -p "$CLAWD_DIR/memory/archive"
echo "  ✅ 归档目录已就绪"
echo ""

# 3. 执行首次归档
echo "🗄️  执行旧数据归档..."
bash "$SCRIPTS_DIR/archive-old-memories.sh"
echo ""

# 4. 检查知识索引大小
echo "📊 检查知识索引..."
KNOWLEDGE_INDEX="$CLAWD_DIR/memory/knowledge-index.md"
if [ -f "$KNOWLEDGE_INDEX" ]; then
    size=$(wc -l < "$KNOWLEDGE_INDEX")
    echo "  当前行数: $size"
    if [ "$size" -gt 800 ]; then
        echo "  ⚠️  知识索引过大，建议执行归档脚本"
    else
        echo "  ✅ 知识索引大小正常"
    fi
fi
echo ""

# 5. 重启监控服务器
echo "🔄 重启监控服务器..."
pkill -f "node.*monitor-server.js" 2>/dev/null || true
sleep 1
cd "$CLAWD_DIR"
nohup node monitor-server.js > monitor.log 2>&1 &
echo "  ✅ 监控服务器已重启 (PID: $!)"
echo ""

# 6. 安装定时任务
echo "⏰ 安装定时归档任务..."
if ! crontab -l 2>/dev/null | grep -q "archive-old-memories"; then
    (crontab -l 2>/dev/null; cat "$SCRIPTS_DIR/crontab-config.txt" | grep -v "^#") | crontab -
    echo "  ✅ 定时任务已安装"
else
    echo "  ✅ 定时任务已存在"
fi
echo ""

# 7. 输出优化结果
echo "✨ 优化完成！"
echo ""
echo "📱 移动端优化效果:"
echo "  • 上下文窗口: 128k → 64k (移动端)"
echo "  • 刷新频率: 5s → 10s (移动端)"
echo "  • 日志条数: 20 → 10 (移动端)"
echo "  • 缓存策略: Service Worker + LocalStorage"
echo "  • 加载策略: 骨架屏 + 懒加载"
echo ""
echo "🔗 访问地址:"
echo "  http://localhost:3000 (自动识别移动端)"
echo ""
echo "📋 后续维护:"
echo "  • 每天凌晨3点自动归档旧数据"
echo "  • 每周日清理超过30天的归档文件"
echo "  • 手动归档: bash $SCRIPTS_DIR/archive-old-memories.sh"
echo ""
echo "🧪 测试建议:"
echo "  1. 使用手机浏览器访问 http://<server-ip>:3000"
echo "  2. 打开Chrome DevTools → Network → 观察加载时间"
echo "  3. 第二次访问应该明显更快（缓存生效）"
