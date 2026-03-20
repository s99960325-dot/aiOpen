#!/bin/bash
# 狗狗军师记忆数据库查询工具
# 用法：./query.sh 关键词
# 或：./query.sh all 查看全部

DB="/Users/seven/.openclaw/workspace/data/memory.db"

if [ -z "$1" ]; then
  echo "用法: $0 <关键词>"
  echo "  $0 all    - 查看所有分类统计"
  echo "  $0 <词>   - 全文搜索"
  exit 1
fi

if [ "$1" = "all" ]; then
  sqlite3 -header -column "$DB" <<'EOF'
SELECT '=== 知识库统计 ===' AS '';
SELECT category, count(*) as cnt FROM knowledge GROUP BY category;
SELECT '=== 最近10条 ===' AS '';
SELECT category, title, created_at FROM knowledge ORDER BY rowid DESC LIMIT 10;
EOF
else
  KEYWORD="$*"
  sqlite3 -header -column "$DB" <<EOF
SELECT '=== 搜索: $KEYWORD ===' AS '';
SELECT category AS 分类, title AS 标题, 
  substr(content, 1, 60) AS 摘要,
  created_at AS 时间
FROM knowledge_fts 
WHERE knowledge_fts MATCH '$KEYWORD'
ORDER BY rank;
EOF
fi
