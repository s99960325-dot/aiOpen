# 小龙虾深度诊断报告
> 时间：2026-03-21 17:20 | 版本：OpenClaw 2026.3.13

## 一、健康检查

| 模块 | 状态 | 详情 |
|------|------|------|
| 版本 | ✅ 最新 | 2026.3.13 (61d171a) |
| Gateway | ✅ 运行中 | local模式，token认证 |
| 模型 | ✅ 正常 | GLM-5-Turbo，缓存命中83% |
| 上下文 | ✅ 健康 | 48k/128k (37%) |
| QMD后端 | ⚠️ 部分工作 | 集合已建但sessions未索引 |
| 插件安全 | ❌ 有漏洞 | plugins.allow为空 |
| 文件权限 | ✅ 正常 | ~/.openclaw 700，配置600 |
| Bun | ✅ 已装 | v1.3.11 |

## 二、发现的问题

### 🔴 P0 — 必须修复

#### 问题1：plugins.allow为空
- **风险**：任何extension都可能自动加载，存在安全风险
- **现状**：日志警告 `[plugins] plugins.allow is empty`
- **修复**：在openclaw.json添加 `"plugins.allow": ["openclaw-lark"]`

#### 问题2：QMD sessions未索引
- **现状**：QMD有2个集合（memory-clawd 6文件、workspace 97文件），但75个session JSONL文件没被索引
- **影响**：memory_search搜不到历史对话内容
- **修复**：在qmd配置中添加 `sessions: { enabled: true }`

#### 问题3：BOOTSTRAP.md和IDENTITY.md冗余
- **BOOTSTRAP.md (679B)**：只用一次的初始化标记，每次对话都加载浪费token
- **IDENTITY.md (318B)**：内容完全重复（身份=SOUL.md，核心=MEMORY.md）
- **修复**：移出workspace或删除

### 🟡 P1 — 建议修复

#### 问题4：QMD未索引evolution/和data/archive/
- **现状**：lessons、research等知识文件没被QMD索引
- **影响**：搜不到经验教训和研究资料
- **修复**：添加 `paths` 配置指向这些目录

#### 问题5：没有sandbox配置
- **现状**：exec工具直接在本机运行，没有容器隔离
- **风险**：恶意prompt可能执行危险命令（虽然有approval机制）
- **建议**：个人使用可暂不配，但如果对外暴露必须加

#### 问题6：学习cron没配
- **现状**：AGENTS.md说每天凌晨3点自动学习，但crontab里没有
- **修复**：加cron任务或确认是否还需要

#### 问题7：HEARTBEAT.md可精简
- **现状**：789B，内容偏多
- **建议**：压缩到200B以内，核心检查项保留即可

### 🟢 P2 — 可选优化

#### 问题8：缺少context-optimizer技能
- GitHub有社区技能（ad2546/context-optimizer），提供语义裁剪
- 当前cache-ttl够用，但长对话可以更精准

#### 问题9：没有配置多模型fallback
- **现状**：只有智谱一个provider
- **风险**：智谱宕机时完全不可用
- **建议**：配一个免费备用（如Google Gemini免费额度）

#### 问题10：clawhub技能未激活
- 内置了clawhub技能但没装过社区技能
- 有5400+可用技能可按需安装

## 三、配置修改清单

### A. openclaw.json 需要改的

```json5
// 1. plugins安全白名单
"plugins": {
  "allow": ["openclaw-lark"],  // ← 新增
  "entries": { ... }
}

// 2. QMD sessions索引
"memory": {
  "qmd": {
    // ... 现有配置 ...
    "sessions": { "enabled": true },  // ← 新增
    "paths": [  // ← 新增
      { "name": "evolution", "path": "~/clawd/evolution", "pattern": "**/*.md" },
      { "name": "archive", "path": "~/clawd/data/archive", "pattern": "**/*.md" }
    ]
  }
}
```

### B. workspace文件需要改的

1. **删除** `BOOTSTRAP.md` — 初始化已完成，没必要保留
2. **删除** `IDENTITY.md` — 内容重复
3. **精简** `HEARTBEAT.md` — 从789B压到200B以内
4. **精简** `AGENTS.md` — 3353B偏大，砍掉冗余段落

### C. crontab需要加的

```
0 3 * * * cd /Users/seven/clawd && echo "学习任务触发" >> /tmp/learning.log
```

## 四、优化后预期效果

| 指标 | 当前 | 优化后 |
|------|------|--------|
| 上下文注入 | 10.9KB/轮 | ~7KB/轮 (砍36%) |
| 记忆搜索覆盖 | memory+workspace | +sessions+evolution+archive |
| 安全等级 | 中 | 高 |
| 单点故障 | 有（智谱） | 降低（可加备用） |

## 五、不需要做的

- ❌ Ollama本地模型 — GLM-5够便宜，装Ollama反而占2GB内存
- ❌ Token Optimizer — 当前上下文管理已经不错
- ❌ NadirClaw路由 — 单模型场景不需要
- ❌ MCP Servers — Brave Search够用

## 六、执行顺序

1. ✅ 改openclaw.json（plugins.allow + QMD sessions + paths）
2. ✅ 重启gateway
3. ✅ 删BOOTSTRAP.md + IDENTITY.md
4. ✅ 精简HEARTBEAT.md + AGENTS.md
5. ⬜ 确认学习cron是否需要
6. ⬜ 可选：配置备用模型provider

---

> seven老师确认后我开始执行第1-4步，预计5分钟搞定。
