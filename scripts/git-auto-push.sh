#!/bin/bash
# Git自动推送脚本
# 检查workspace目录，如果有修改就提交并推送到GitHub

cd /Users/seven/clawd

# 检查是否有修改
if [ -n "$(git status --porcelain)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到修改，准备提交并推送..."
    
    # 添加所有修改
    git add -A
    
    # 提交（使用时间戳作为提交信息）
    git commit -m "Auto commit: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 推送到远程仓库
    git push origin main
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 推送完成"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 无修改，跳过推送"
fi
