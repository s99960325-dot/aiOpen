#!/bin/bash
# SQLite → MEMORY.md 同步脚本 v6
# 精简版：固定模板 + 最近5条 + 统计，目标 <2KB
# 每6小时cron触发

set -euo pipefail

WORKSPACE="/Users/seven/.openclaw/workspace"
DB="$WORKSPACE/data/memory.db"
MEMORY_MD="$WORKSPACE/MEMORY.md"
HEADER_FILE="$WORKSPACE/MEMORY.md.header"
MEMORY_DIR="$WORKSPACE/memory"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$MEMORY_DIR"

# 用Python生成，避免shell pipe子shell问题
python3 << 'PYEOF'
import sqlite3, os, datetime

WORKSPACE = "/Users/seven/.openclaw/workspace"
DB = os.path.join(WORKSPACE, "data/memory.db")
HEADER = os.path.join(WORKSPACE, "MEMORY.md.header")
MEMORY_MD = os.path.join(WORKSPACE, "MEMORY.md")
MEMORY_DIR = os.path.join(WORKSPACE, "memory")
TODAY = datetime.date.today().isoformat()

db = sqlite3.connect(DB)

# 1. 固定头部
with open(HEADER, "r") as f:
    content = f.read().strip()

# 2. 最近5条
rows = db.execute("SELECT category, title, substr(content,1,50), source FROM knowledge ORDER BY rowid DESC LIMIT 5").fetchall()
content += "### 最近更新\n"
for cat, title, snippet, source in rows:
    t = title.replace("[", "").replace("]", "")
    line = f"- [{cat}] {t}"
    if snippet and snippet.strip():
        line += f": {snippet}..."
    if source:
        line += f" ({source})"
    content += line + "\n"
content += "\n"

# 3. 统计
content += "### 数据统计\n"
stats = [
    ("知识", "knowledge"),
    ("案例", "cases"),
    ("法律", "laws"),
    ("人脉", "people"),
    ("项目", "projects"),
]
for label, table in stats:
    try:
        count = db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        content += f"- {label}: {count}\n"
    except:
        content += f"- {label}: 0\n"
content += f"- 详细查询: `data/query.sh <关键词>`\n\n"
content += f"> 同步: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')} | 源: data/memory.db\n"

# 写入
with open(MEMORY_MD, "w") as f:
    f.write(content)
print("[sync] MEMORY.md updated")

# 4. 每日日志
total_new = 0
for table in ["knowledge", "cases", "laws", "people", "projects"]:
    try:
        n = db.execute(f"SELECT count(*) FROM {table} WHERE date(created_at) = '{TODAY}'").fetchone()[0]
        total_new += n
    except:
        pass

if total_new > 0:
    daily_path = os.path.join(MEMORY_DIR, f"{TODAY}.md")
    k_rows = db.execute(f"SELECT category, title, substr(content,1,200), source FROM knowledge WHERE date(created_at) = '{TODAY}' ORDER BY rowid").fetchall()
    
    mode = "a" if os.path.exists(daily_path) else "w"
    with open(daily_path, mode) as f:
        if mode == "w":
            f.write(f"# {TODAY} - 记忆同步日志\n\n")
        if k_rows:
            f.write(f"## 新增知识 ({datetime.datetime.now().strftime('%H:%M')})\n")
            for cat, title, cnt, src in k_rows:
                f.write(f"- **[{cat}] {title}**: {cnt}")
                if src:
                    f.write(f" ({src})")
                f.write("\n")
            f.write("\n")
    print(f"[sync] {daily_path} updated ({total_new} new)")
else:
    print("[sync] No new entries today")

db.close()
print("[sync] Done.")
PYEOF
