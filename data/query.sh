#!/bin/bash
# 狗狗军师记忆数据库查询工具 v2
# 用法：./query.sh <关键词> | ./query.sh all
# 增强：进化/待办/最近对话/分类搜索

# 动态获取项目根目录（脚本所在目录的父目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
DB="$WORKSPACE/data/memory.db"

if [ -z "$1" ]; then
  echo "用法: $0 <命令> [参数]"
  echo "  $0 all             - 总览统计+最近知识"
  echo "  $0 <关键词>        - 全文搜索知识库"
  echo "  $0 cat <分类>      - 按分类搜索(技术/法律/灰产/赚钱/进化)"
  echo "  $0 case [关键词]   - 搜索案例"
  echo "  $0 law [关键词]    - 搜索法律"
  echo "  $0 todo            - 查看待办"
  echo "  $0 evo             - 查看进化记录"
  echo "  $0 recent [N]      - 最近N条知识(默认10)"
  echo "  $0 sync            - 检查FTS索引同步状态"
  exit 1
fi

CMD="$1"
shift

case "$CMD" in
  all)
    sqlite3 -header -column "$DB" <<'EOF'
.mode column
.headers on
SELECT '=== 知识库 ===' AS '';
SELECT category AS 分类, count(*) AS 数量 FROM knowledge GROUP BY category ORDER BY count(*) DESC;
SELECT '=== 案例 ===' AS '';
SELECT count(*) AS 数量 FROM cases;
SELECT '=== 法律 ===' AS '';
SELECT count(*) AS 数量 FROM laws;
SELECT '=== 最近10条 ===' AS '';
SELECT category AS 分类, title AS 标题, created_at AS 时间 FROM knowledge ORDER BY rowid DESC LIMIT 10;
EOF
    ;;

  cat)
    CAT="${*:-}"
    if [ -z "$CAT" ]; then
      sqlite3 -header -column "$DB" "SELECT category AS 分类, count(*) AS 数量 FROM knowledge GROUP BY category ORDER BY count(*) DESC;"
    else
      sqlite3 -header -column "$DB" <<EOF
SELECT k.category AS 分类, k.title AS 标题,
  substr(k.content, 1, 100) AS 摘要,
  k.created_at AS 时间
FROM knowledge k
WHERE k.category LIKE '%$CAT%'
ORDER BY k.rowid DESC
LIMIT 20;
EOF
    fi
    ;;

  case)
    KEYWORD="${*:-}"
    if [ -z "$KEYWORD" ]; then
      sqlite3 -header -column "$DB" "SELECT name AS 名称, type AS 类型, risk_level AS 风险, legal_status AS 合规 FROM cases ORDER BY rowid DESC;"
    else
      sqlite3 -header -column "$DB" "SELECT name AS 名称, type AS 类型, description AS 描述, risk_level AS 风险 FROM cases WHERE name LIKE '%$KEYWORD%' OR description LIKE '%$KEYWORD%' OR type LIKE '%$KEYWORD%';"
    fi
    ;;

  law)
    KEYWORD="${*:-}"
    if [ -z "$KEYWORD" ]; then
      sqlite3 -header -column "$DB" "SELECT crime_name AS 罪名, article AS 条款, risk_level AS 风险 FROM laws ORDER BY rowid DESC;"
    else
      sqlite3 -header -column "$DB" "SELECT crime_name AS 罪名, article AS 条款, description AS 描述, penalty AS 处罚 FROM laws WHERE crime_name LIKE '%$KEYWORD%' OR description LIKE '%$KEYWORD%';"
    fi
    ;;

  todo)
    sqlite3 -header -column "$DB" <<EOF
SELECT k.category AS 分类, k.title AS 标题,
  substr(k.content, 1, 120) AS 详情,
  k.created_at AS 时间
FROM knowledge k
WHERE k.category = '需求' OR k.category = '待办' OR k.title LIKE '%待办%' OR k.title LIKE '%TODO%'
ORDER BY k.rowid DESC
LIMIT 20;
EOF
    ;;

  evo)
    sqlite3 -header -column "$DB" <<EOF
SELECT k.title AS 标题,
  substr(k.content, 1, 150) AS 详情,
  k.created_at AS 时间
FROM knowledge k
WHERE k.category = '进化' OR k.tags LIKE '%进化%' OR k.tags LIKE '%教训%'
ORDER BY k.rowid DESC
LIMIT 20;
EOF
    ;;

  recent)
    N="${*:-10}"
    sqlite3 -header -column "$DB" <<EOF
SELECT k.category AS 分类, k.title AS 标题,
  substr(k.content, 1, 100) AS 摘要,
  k.created_at AS 时间
FROM knowledge k
ORDER BY k.rowid DESC
LIMIT $N;
EOF
    ;;

  sync)
    echo "=== FTS同步状态 ==="
    sqlite3 "$DB" <<EOF
SELECT 'knowledge表' AS 表, count(*) AS 总数 FROM knowledge
UNION ALL
SELECT 'FTS索引' AS 表, count(*) AS 数量 FROM knowledge_fts;
EOF
    echo ""
    echo "如数量不一致，运行: sqlite3 $DB \"INSERT INTO knowledge_fts(rowid,category,title,content,source,tags,url) SELECT id,category,title,content,source,tags,url FROM knowledge WHERE id NOT IN (SELECT rowid FROM knowledge_fts);\""
    ;;

  *)
    KEYWORD="$CMD $*"
    sqlite3 -header -column "$DB" <<EOF
SELECT k.category AS 分类, k.title AS 标题,
  substr(k.content, 1, 100) AS 摘要,
  k.source AS 来源
FROM knowledge_fts f
JOIN knowledge k ON k.id = f.rowid
WHERE knowledge_fts MATCH '$KEYWORD'
ORDER BY rank
LIMIT 20;
EOF
    ;;
esac
