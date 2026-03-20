#!/bin/bash
# 狗狗军师记忆数据库查询工具
# 用法：./query.sh <关键词> | ./query.sh all

DB="/Users/seven/.openclaw/workspace/data/memory.db"

if [ -z "$1" ]; then
  echo "用法: $0 <关键词>"
  echo "  $0 all    - 查看所有分类统计"
  echo "  $0 <词>   - 全文搜索知识库"
  echo "  $0 case   - 搜索案例"
  echo "  $0 law    - 搜索法律"
  exit 1
fi

if [ "$1" = "all" ]; then
  sqlite3 -header -column "$DB" <<'EOF'
.mode column
.headers on
SELECT '=== 知识库 ===' AS '';
SELECT category AS 分类, count(*) AS 数量 FROM knowledge GROUP BY category;
SELECT '=== 案例 ===' AS '';
SELECT count(*) AS 数量 FROM cases;
SELECT '=== 法律 ===' AS '';
SELECT count(*) AS 数量 FROM laws;
SELECT '=== 最近10条知识 ===' AS '';
SELECT category AS 分类, title AS 标题, created_at AS 时间 FROM knowledge ORDER BY rowid DESC LIMIT 10;
EOF

elif [ "$1" = "case" ]; then
  shift
  KEYWORD="${*:-}"
  if [ -z "$KEYWORD" ]; then
    sqlite3 -header -column "$DB" "SELECT name AS 名称, type AS 类型, risk_level AS 风险, legal_status AS 合规 FROM cases ORDER BY rowid DESC;"
  else
    sqlite3 -header -column "$DB" "SELECT name AS 名称, type AS 类型, description AS 描述, risk_level AS 风险 FROM cases WHERE name LIKE '%$KEYWORD%' OR description LIKE '%$KEYWORD%' OR type LIKE '%$KEYWORD%';"
  fi

elif [ "$1" = "law" ]; then
  shift
  KEYWORD="${*:-}"
  if [ -z "$KEYWORD" ]; then
    sqlite3 -header -column "$DB" "SELECT crime_name AS 罪名, article AS 条款, risk_level AS 风险 FROM laws ORDER BY rowid DESC;"
  else
    sqlite3 -header -column "$DB" "SELECT crime_name AS 罪名, article AS 条款, description AS 描述, penalty AS 处罚 FROM laws WHERE crime_name LIKE '%$KEYWORD%' OR description LIKE '%$KEYWORD%';"
  fi

else
  KEYWORD="$*"
  sqlite3 -header -column "$DB" <<EOF
SELECT k.category AS 分类, k.title AS 标题,
  substr(k.content, 1, 80) AS 摘要,
  k.source AS 来源
FROM knowledge_fts f
JOIN knowledge k ON k.id = f.rowid
WHERE knowledge_fts MATCH '$KEYWORD'
ORDER BY rank
LIMIT 20;
EOF
fi
