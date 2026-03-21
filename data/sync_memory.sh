#!/bin/bash
# SQLite → MEMORY.md 同步脚本 v7
# 精简版：固定模板 + 最近5条 + 统计 + 知识库索引
# 每6小时cron触发

set -euo pipefail

WORKSPACE="/Users/seven/clawd"
DB="$WORKSPACE/data/memory.db"
MEMORY_MD="$WORKSPACE/MEMORY.md"
MEMORY_DIR="$WORKSPACE/memory"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$MEMORY_DIR"

python3 << 'PYEOF'
import sqlite3, os, datetime

WORKSPACE = "/Users/seven/clawd"
DB = os.path.join(WORKSPACE, "data/memory.db")
MEMORY_MD = os.path.join(WORKSPACE, "MEMORY.md")
MEMORY_DIR = os.path.join(WORKSPACE, "memory")
TODAY = datetime.date.today().isoformat()

db = sqlite3.connect(DB)

# 1. 固定头部
header = """# MEMORY.md - 狗狗军师长期记忆
> 自动同步，详情查 `data/query.sh <关键词>`

### 身份
- 狗狗军师，seven老师的私人军师，全领域智囊
- 收到消息先👀，先结论后原因，不超300字，不确定打问号

### 技术栈
- OpenClaw + Telegram + 飞书 + GLM-5-Turbo
- SQLite记忆数据库（data/memory.db）
- 阿里云服务器：47.237.85.150

### 待办
- 买中转API key配入OpenClaw
- 多设备互通方案待确认

"""

# 2. 最近5条
rows = db.execute("SELECT category, title, substr(content,1,60), source FROM knowledge ORDER BY rowid DESC LIMIT 5").fetchall()
content = header + "### 最近更新\n"
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
stats = [("知识", "knowledge"), ("案例", "cases"), ("法律", "laws"), ("人脉", "people"), ("项目", "projects")]
for label, table in stats:
    try:
        count = db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        content += f"- {label}: {count}\n"
    except:
        content += f"- {label}: 0\n"
content += f"- 详细查询: `data/query.sh <关键词>`\n\n"
content += f"> 同步: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')} | 源: data/memory.db\n"

with open(MEMORY_MD, "w") as f:
    f.write(content)
print("[sync] MEMORY.md updated")

# 4. 知识库全文索引（供memory_search语义搜索）
# 每条知识一行：标题 + 前200字内容 + 来源
# 这样memory_search就能搜到SQLite里的所有知识
all_rows = db.execute("""
    SELECT category, title, content, source, created_at 
    FROM knowledge 
    ORDER BY rowid DESC
""").fetchall()

idx_path = os.path.join(MEMORY_DIR, "knowledge-index.md")
with open(idx_path, "w") as f:
    f.write("# 知识库索引\n> 由sync_memory.sh自动生成，供memory_search语义搜索\n\n")
    for cat, title, content, source, created_at in all_rows:
        date_str = created_at[:10] if created_at else ""
        f.write(f"## [{cat}] {title}\n")
        # 写前200字内容，让向量搜索能命中
        if content:
            f.write(f"{content[:200]}\n")
        if source:
            f.write(f"来源: {source} | {date_str}\n")
        f.write("\n")
print(f"[sync] knowledge-index.md updated ({len(all_rows)} entries)")

# 5. 每日日志
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

# 6. QMD索引更新（独立检索引擎）
echo "[sync] Updating QMD index..."
qmd update >> /tmp/memory-sync.log 2>&1
qmd embed >> /tmp/memory-sync.log 2>&1
echo "[sync] QMD index updated"
