# MEMORY.md - 狗狗军师长期记忆
> 自动同步，详情查 `data/query.sh <关键词>`

### 身份
- 狗狗军师，seven老师的私人军师，全领域智囊
- 收到消息先👀，先结论后原因，不超300字，不确定打问号

### 技术栈
- OpenClaw v2026.3.13 + Telegram + 飞书 + GLM-5-Turbo
- QMD记忆后端（本地向量搜索，省token）
- SQLite记忆数据库（data/memory.db）
- 阿里云服务器：47.237.85.150

### 待办
- 买中转API key配入OpenClaw
- 多设备互通方案待确认

### 最近更新
- [升级] QMD记忆后端: 从默认SQLite切换到QMD引擎，本地模型(paraphrase-multilingual-MiniLM-L12-v2)做向量搜索，记忆检索零token消耗。配置在memory.qmd，5分钟自动刷新索引
- [规则] 先查后答原则: seven老师要求：回答问题前先查资料（web_search、memory_search、qmd等），查完再给结论，不拍...
- [工具] Brave Search API配置: Brave Search API key已配置到tools.web.search.apiKey，重启后可正常使用web_...
- [评估] 微信操作风险评估: Peekaboo可以操作微信界面，但不建议使用。原因：1.隐私风险 2.风控封号 3.操作不稳定。seven老师已登录微...
- [技术方案] 上下文记忆优化: OpenClaw v2026.3.7推出ContextEngine架构，lossless-claw插件需3.7+，但op...
- [决策] 自动学习降频: 持续学习从每小时改为每天凌晨3点一次。只聚焦引流新玩法、变现模式、灰产案例、监管变化。3轮内完成，不学基础科普。预计省8...

### 数据统计
- 知识: 150
- 案例: 11
- 法律: 5
- 人脉: 0
- 项目: 1
- 详细查询: `data/query.sh <关键词>`

> 同步: 2026-03-21 17:07:39  | 源: data/memory.db
