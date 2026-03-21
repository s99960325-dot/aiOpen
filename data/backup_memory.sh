#!/bin/bash
# 备份记忆数据库到GitHub memory分支
cd ~/.openclaw/memory
git add -A
if git diff --cached --quiet; then
  exit 0
fi
git commit -m "auto-backup: $(date +%Y-%m-%d\ %H:%M)"
git push origin main:memory 2>/dev/null

# 同时备份workspace
cd ~/clawd
git add -A
if git diff --cached --quiet; then
  exit 0
fi
git commit -m "auto-sync: $(date +%Y-%m-%d\ %H:%M)"
git push 2>/dev/null
