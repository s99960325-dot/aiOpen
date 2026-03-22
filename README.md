# 🐕 狗狗军师 - AI私人智囊系统

全领域智囊 + 执行顾问，基于 OpenClaw 多通道架构运行。

---

## 🎯 核心定位

| 角色 | 能力 |
|------|------|
| 决策判断 | 可行性分析、风险评估 |
| 方案设计 | 技术路线、实施步骤 |
| 任务分配 | 调度其他机器人执行 |
| 结果分析 | 数据解读、经验提炼 |

---

## 🧠 记忆系统（核心）

四层架构，保证核心信息零丢失：

```
QMD向量搜索（本地）           ← BM25+向量+重排序+查询扩展，零token
         ↕
SQLite数据库(data/memory.db)  ← 实时写入，持久存储
         ↓ 每6小时自动同步
    MEMORY.md                 ← 核心索引，<3K tokens
         ↓ 每日记录
  memory/YYYY-MM-DD.md        ← 当天详细日志
```

- **QMD搜索**：4个本地模型（embeddinggemma-300M / Qwen3-Embedding-0.6B / qwen3-reranker-0.6b / qmd-query-expansion-1.7B），按需加载不占内存
- 查询脚本：`data/query.sh <关键词>`
- 同步脚本：`data/sync_memory.sh`（cron每6小时）
- 数据库分类：知识(151) / 案例(11) / 法律 / 人脉 / 项目(1)
- GitHub备份：记忆数据库 → `aiOpen/memory` 分支，每6小时自动推送

---

## 🔧 技术栈

- **架构**：OpenClaw 多通道网关
- **通道**：Telegram（主力）+ 飞书（工作用）
- **模型**：GLM-5-Turbo（智谱）
- **记忆**：SQLite + Markdown 双层
- **工具链**：浏览器自动化 / GitHub / Cron定时任务
- **编程**：Claude Code / ACP（备用）

### GitHub备份策略
| 分支 | 内容 | 频率 |
|------|------|------|
| `main` | workspace配置 | 每6小时 + 重要操作后 |
| `memory` | 记忆数据库 | 每6小时 |

---

## 📊 更新日志

- **2026-03-22**：AGENTS.md优化 + token精简 + git清理
- **2026-03-21**：QMD向量搜索部署、GitHub记忆备份、飞书插件、Peekaboo安装
