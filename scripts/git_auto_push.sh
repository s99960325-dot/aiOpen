#!/bin/bash

# git自动推送脚本
cd /Users/seven/clawd

echo "=== Git自动推送检查 ==="
echo "时间: $(date)"
echo "目录: $(pwd)"

# 检查是否有未提交的更改
if git status --porcelain | grep -q .; then
    echo "发现未提交的更改:"
    git status --short
    
    # 添加所有更改
    git add .
    
    # 提交
    commit_message="Auto commit by OpenClaw at $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message"
    
    # 推送到GitHub
    echo "正在推送到GitHub..."
    if git push origin main; then
        echo "✅ 推送成功: $commit_message"
    else
        echo "❌ 推送失败"
        exit 1
    fi
else
    echo "✅ 工作目录干净，无需提交"
    
    # 尝试拉取更新
    echo "检查远程更新..."
    if git pull origin main; then
        echo "✅ 已同步远程更新"
    else
        echo "⚠️ 无法拉取更新，继续执行"
    fi
fi

echo "=== 检查完成 ==="