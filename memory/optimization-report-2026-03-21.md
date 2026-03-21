# 小龙虾优化报告 v1
> 生成时间：2026-03-21 17:17 | 版本：OpenClaw 2026.3.13

## 一、当前状态概览

| 指标 | 状态 | 评价 |
|------|------|------|
| 版本 | 2026.3.13 (61d171a) | ✅ 最新 |
| 模型 | GLM-5-Turbo (智谱) | ✅ 便宜够用 |
| 缓存命中率 | 83% | ✅ 不错 |
| 上下文占用 | 37% (48k/128k) | ✅ 健康 |
| 记忆后端 | QMD (本地向量) | ✅ 已升级 |
| Ollama本地模型 | ❌ 未安装 | ⚠️ 缺失 |
| 系统文件总大小 | 10.9KB | ✅ 精简 |

## 二、已优化项 ✅

1. **QMD记忆后端** — 零token语义搜索，本地BM25+向量+rerank
2. **上下文自动裁剪** — cache-ttl 6h过期，自动清理
3. **自动压缩+记忆保护** — 压缩前自动flush记忆
4. **对话归档** — auto_archive.sh自动归档向量化
5. **Brave Search** — 已配置，直接可用
6. **Git自动同步** — 每小时auto-commit+push

## 三、待优化项（按优先级）

### 🔴 P0 — 立即可做

#### 1. 安装Ollama本地模型兜底
- **现状**：所有请求都走智谱API
- **方案**：安装Ollama + qwen2.5:3b，简单闲聊走本地，零成本
- **预期**：省30-50% API调用量
- **操作**：`brew install ollama && ollama pull qwen2.5:3b`，配置model routing

#### 2. 上下文注入精简
- **现状**：8个文件共10.9KB每次全量加载
- **可砍**：
  - BOOTSTRAP.md (679B) — 只用一次，可移出workspace
  - IDENTITY.md (318B) — 内容已在SOUL.md/MEMORY.md里，重复
  - HEARTBEAT.md (789B) — 可缩短到5行以内
- **预期**：每轮省~1.8KB上下文

#### 3. plugins.allow白名单
- **现状**：为空，任何extension都可能自动加载
- **风险**：安全隐患
- **方案**：加 `"plugins.allow": ["openclaw-lark"]`

### 🟡 P1 — 短期优化

#### 4. 模型路由配置
- **现状**：所有请求走GLM-5-Turbo
- **方案**：配置routing，按复杂度分流
  - 简单闲聊/打招呼 → Ollama本地（零成本）
  - 常规问答 → GLM-5-Turbo（便宜）
  - 复杂分析 → 可升级主力模型
- **参考**：NadirClaw (GitHub) 自动分流方案

#### 5. 记忆分层规范化
- **现状**：基本有但不够规范
- **方案**：
  - MEMORY.md控制在50行以内（现在太长）
  - 深度知识分目录：memory/topics/、memory/decisions/
  - people/、projects/目录建立（目前都是0）
- **预期**：搜索更精准，上下文更干净

#### 6. QMD extraPaths扩展
- **现状**：只索引默认memory目录
- **方案**：加入evolution/lessons/、data/archive/等知识库

### 🟢 P2 — 中期优化

#### 7. 技能扩展
- **已有**：飞书全套、healthcheck、qmd、weather、browser等
- **推荐加装**：
  - `clawhub` — 技能市场，一键装新技能
  - `github` — PR/Issue管理（引流项目用得上）
  - `coding-agent` — 编程任务兜底

#### 8. Token Optimizer
- **项目**：openclaw-token-optimizer (GitHub开源)
- **功能**：自动精简skills输出，减少重复token
- **预期**：省15-30% token

#### 9. MCP Servers集成
- 2026版新特性，统一接入多搜索引擎
- 当前Brave够用，但可以加Perplexity做补充

#### 10. 定时任务优化
- **现状**：6小时同步DB→MEMORY.md + 每小时git同步
- **建议**：加QMD索引健康检查（每天一次）
- **缺失**：学习任务cron（之前说每天凌晨3点，但crontab里没配）

## 四、安全加固

| 项 | 状态 | 建议 |
|----|------|------|
| gateway.auth | ✅ token模式 | 保持 |
| plugins.allow | ⚠️ 空 | 加白名单 |
| trustedProxies | ⚠️ 空 | 如需反向代理需配 |
| groupAllowFrom | ⚠️ 空 | 群聊白名单没配（当前DM-only没问题） |
| exec安全 | ✅ 有approval机制 | 保持 |

## 五、成本估算

| 场景 | 当前 | 优化后 |
|------|------|--------|
| 简单闲聊 | ~0.002元/次 | 0元（本地） |
| 常规问答 | ~0.002元/次 | ~0.002元/次 |
| 复杂分析 | ~0.01元/次 | ~0.01元/次 |
| **月均（估）** | ~5-10元 | ~2-5元 |

## 六、执行路线图

**本周**：P0全部搞定（Ollama + 精简文件 + plugins白名单）
**下周**：P1前3项（模型路由 + 记忆规范 + QMD扩展路径）
**月底前**：P2按需装（Token Optimizer + 技能扩展）

---

> 待seven老师确认后执行。
