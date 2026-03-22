#!/bin/bash
cd /Users/seven/clawd

# 检查是否有变动
git status --porcelain 2>/dev/null | head -1
if [ $? -eq 0 ]; then
    echo "Workspace has changes"
    
    # 添加所有变动
    git add -A
    
    # 提交，使用当前时间作为提交信息
    git commit -m "auto: $(date '+%Y-%m-%d %H:%M')"
    
    # 推送到 main 分支
    git push origin main
fi
