# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics.

## 记忆系统
- **QMD后端**（主力）：本地BM25+向量+rerank搜索，零token消耗
  - 配置：openclaw.json → memory.backend = "qmd"
  - 本地模型：paraphrase-multilingual-MiniLM-L12-v2
  - 自动索引刷新：每5分钟
- SQLite数据库：data/memory.db（知识/案例/法律/人脉/项目）
- 查询脚本：data/query.sh <关键词>
- 归档脚本：data/auto_archive.sh（自动归档对话+向量化）
- 同步脚本：data/sync_memory.sh（每6小时cron自动同步DB→MEMORY.md）
- 日志目录：memory/YYYY-MM-DD.md（每日详细记录）

## 服务器
- 阿里云：47.237.85.150（朋友/团队机器人）
- 系统: Linux，OpenClaw 2026.3.13

## 通道
- Telegram（主力）
- 飞书（工作用）

## 模型
- 主力：GLM-5-Turbo（智谱，1/glm-5-turbo）
- 备选：待接入中转API（方案已研究，models.providers配置）

## 工具链
- 浏览器自动化（调研/截图）
- GitHub（知识库/代码管理 + 监控大屏托管）
- Cron定时任务（日报/同步/备份）
- Claude Code（备用编程）

## 监控大屏
- 本地文件：/Users/seven/clawd/monitor.html
- GitHub Pages 托管：https://[username].github.io/[repo]/monitor.html
- 自动刷新：5秒一次，支持手动刷新/开关
- 深色主题，响应式适配

## 待配置
- 中转API key（seven老师购买后配置）
- 多设备互通方案（待确认需求）
