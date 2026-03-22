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

## 📂 目录结构

### 核心配置
| 文件 | 用途 |
|------|------|
| `SOUL.md` | 灵魂设定：身份档案+性格+思维模式+沟通风格+进化本能 |
| `USER.md` | 主人档案：基础信息+性格+偏好+核心需求+禁忌 |
| `AGENTS.md` | 运行触发：启动流程+分析框架+红线+行为指令+记忆管理+上下文管理 |
| `EVOLUTION.md` | 进化体系：犯错处理+自我进化+进化统计+每日任务 |
| `MEMORY.md` | 记忆索引：查询指引+关键摘要+数据统计+同步时间 |
| `TOOLS.md` | 工具清单、服务器、通道配置 |
| `HEARTBEAT.md` | 心跳自检清单 |

*（IDENTITY.md已删除，内容合并到SOUL.md）*

### 数据层
| 路径 | 用途 |
|------|------|
| `data/memory.db` | SQLite记忆数据库 |
| `data/query.sh` | 关键词查询脚本 |
| `data/sync_memory.sh` | DB→MEMORY.md同步脚本 |
| `memory/` | 每日详细日志 |

### 进化系统
| 路径 | 用途 |
|------|------|
| `evolution/lessons/` | 教训记录 |
| `evolution/evals/` | 评分日志 |

---

## 🔧 技术栈

- **架构**：OpenClaw 多通道网关
- **通道**：Telegram（主力）+ 飞书（工作用）
- **模型**：GLM-5-Turbo（智谱）
- **记忆**：SQLite + Markdown 双层
- **工具链**：浏览器自动化 / GitHub / Cron定时任务
- **编程**：Claude Code / ACP（备用）
- **服务器**：阿里云 47.237.85.150（团队机器人）

### GitHub备份策略
| 分支 | 内容 | 频率 |
|------|------|------|
| `main` | workspace代码+配置 | 每6小时 + 重要操作后 |
| `memory` | 记忆数据库(SQLite) | 每6小时 |

### 已装Skills（18/63）
| 类别 | Skills |
|------|--------|
| 飞书全家桶 | 多维表格、日历、IM、文档创建/获取/更新、任务、问题排查、频道规则 |
| 内置工具 | weather、healthcheck、peekaboo、qmd、safety-executor、skill-creator、slack |

---

## 📅 每日任务

- **09:00** 灰产资讯日报（监管动态 / 新路子 / 项目推荐 / 风险预警）

---

## 📊 更新日志

- **2026-03-21**：QMD向量搜索部署（4模型）、GitHub记忆备份（memory分支）、自动备份cron、飞书插件全家桶、Peekaboo安装
- **2026-03-20**：记忆系统升级（SQLite铁律）、核心配置更新、GitHub推送修复
- **2026-03-19**：初始化 + 进化体系部署 + Telegram接入 + 闲鱼支付协议调研
