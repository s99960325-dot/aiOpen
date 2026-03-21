#!/bin/bash
cd /Users/seven/.openclaw/workspace
git status --porcelain 2>/dev/null | head -1
if [ $? -eq 0 ]; then
    echo "Workspace has changes"
fi
