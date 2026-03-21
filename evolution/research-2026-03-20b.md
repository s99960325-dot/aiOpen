# OpenClaw 生态深度研究报告

> 研究日期：2026-03-20
> 覆盖范围：ClawHub/ClawdHub、Skills机制、第三方Skills推荐、Node节点功能

---

## 一、ClawHub 与 ClawdHub 的关系

### 1.1 核心结论

**ClawHub（clawhub.ai）是 OpenClaw 官方的 skill 注册中心**，而 **ClawdHub（clawdhub.com）是第三方/社区 fork 的替代 CLI**。

| 项目 | ClawHub（官方） | ClawdHub（社区） |
|------|----------------|-----------------|
| 网站 | clawhub.ai | clawdhub.com |
| GitHub | github.com/openclaw/clawhub | 社区维护 |
| CLI 安装 | `npm i -g clawhub` | `npm i -g clawdhub` |
| 默认注册表 | clawhub.ai | clawdhub.com |
| 注册表 API | 从 `/.well-known/clawhub.json` 自动发现 | 从 `/.well-known/clawdhub.json` 自动发现 |
| 生态规模 | 13,700+ skills（2026.02） | 未明确统计 |
| 安全审计 | VirusTotal 集成 + Snyk 扫描 | 无来源验证（ClawHub 页面有安全警告） |
| 身份认证 | GitHub OAuth（账号需≥1周） | 未明确 |

### 1.2 ClawHub CLI 关键参数

```bash
# 安装 CLI
npm i -g clawhub

# 指定不同注册表源
clawhub install <slug> --registry https://clawdhub.com  # 连接 ClawdHub
clawhub install <slug> --site https://clawdhub.com      # 浏览器登录用不同站

# 环境变量方式
CLAWHUB_REGISTRY=https://clawdhub.com clawhub install <slug>   # 旧环境变量名
CLAWHUB_SITE=https://clawdhub.com clawhub login                  # 旧环境变量名

# 所有全局参数
--workdir <dir>        # 工作目录（默认当前目录，回退到 OpenClaw workspace）
--dir <dir>            # skills 目录（相对于 workdir，默认 skills）
--site <url>           # 站点基础 URL（浏览器登录）
--registry <url>       # 注册表 API 基础 URL
--no-input             # 非交互模式
```

### 1.3 安全建议

- **优先使用官方 ClawHub（clawhub.ai）**，ClawdHub 上已发布的一个 skill（steipete/clawdhub）被标注了「来源不透明」警告
- 安装前检查 skill 的 VirusTotal 报告（ClawHub 页面有集成）
- 官方建议把第三方 skill 视为不受信任代码，安装前务必审查 SKILL.md 内容

---

## 二、OpenClaw Skills 安装机制详解

### 2.1 Skills 加载位置与优先级

```
优先级从高到低：

1. <workspace>/skills/          → 工作区 skills（单 agent 专用，最高优先）
2. ~/.openclaw/skills/          → 托管/本地 skills（所有 agent 共享）
3. 内置 skills（npm 包自带）     → 最低优先级

4. skills.load.extraDirs 配置  → 额外目录（优先级低于以上三者）
```

### 2.2 SKILL.md 完整格式规范

#### 最小结构
```
my-skill/
└── SKILL.md    （唯一必需文件）
```

#### 完整 Frontmatter 字段

```yaml
---
# === 必需字段 ===
name: skill-name                    # skill 标识名
description: 一句话描述 skill 功能   # agent 用来判断是否激活

# === 可选字段 ===
homepage: https://example.com       # 主页 URL（macOS Skills UI 显示为 "Website"）
user-invocable: true|false          # 是否暴露为 slash 命令（默认 true）
disable-model-invocation: true|false # 是否排除在模型提示之外（默认 false）
command-dispatch: tool              # slash 命令直接分发到工具（可选）
command-tool: tool-name             # 分发到的工具名（配合 command-dispatch 使用）
command-arg-mode: raw               # 参数传递模式（默认 raw）

# === metadata（单行 JSON 对象）===
metadata:
  {
    "openclaw": {
      "always": false,                    # 始终加载（跳过其他门控）
      "emoji": "🤖",                      # macOS Skills UI 的 emoji
      "homepage": "https://...",           # 同上 homepage
      "os": ["darwin", "linux", "win32"],  # 限制平台
      "requires": {
        "bins": ["uv"],                    # 必须存在于 PATH 的二进制
        "anyBins": ["node", "bun"],        # 至少一个存在
        "env": ["GEMINI_API_KEY"],         # 必须存在的环境变量
        "config": ["browser.enabled"]      # 必须为 true 的 openclaw.json 路径
      },
      "primaryEnv": "GEMINI_API_KEY",      # 关联的 apiKey 配置
      "install": [                          # 安装器规格（macOS Skills UI 用）
        {
          "id": "brew",
          "kind": "brew",
          "formula": "gemini-cli",
          "bins": ["gemini"],
          "label": "Install Gemini CLI (brew)",
          "os": ["darwin"]                  # 可选平台过滤
        }
      ]
    }
  }
---
```

### 2.3 指令内容区

Frontmatter 之后是 Markdown 格式的指令内容：
- 用 `{baseDir}` 引用 skill 文件夹路径
- 描述具体的工作流、步骤、API 调用方式
- 可以引用同一目录下的其他文件（脚本、配置等）

### 2.4 配置覆盖（openclaw.json）

```json5
{
  skills: {
    entries: {
      "skill-name": {
        enabled: true,
        apiKey: { source: "env", provider: "default", id: "API_KEY" },
        env: { API_KEY: "xxx" },
        config: { customField: "value" }
      }
    },
    allowBundled: ["skill-a", "skill-b"]  // 白名单限制内置 skills
  },
  load: {
    watch: true,
    watchDebounceMs: 250
  }
}
```

### 2.5 关键特性

- **渐进式加载**：启动时只加载 name + description（约125 tokens/10个 skill），激活时才读完整指令
- **Session 快照**：每次 session 开始时冻结 skill 列表，修改后下次 session 生效
- **热重载**：开启 watch 后 SKILL.md 变更会自动刷新
- **Token 消耗公式**：`total = 195 + Σ(97 + len(name) + len(description) + len(location))` 字符

---

## 三、最值得安装的第三方 Skills 推荐

### 3.1 生态安全现状（2026.03）

ClawHub 注册表已有 **13,700+ skills**，但安全审计显示：
- Snyk 审计发现 **13.4% 存在严重问题**（恶意代码、prompt 注入、泄露 API key）
- Koi Security 扫描 2,857 个 skill，**341 个在窃取用户数据**
- VoltAgent 的 awesome-openclaw-skills 从中筛选了 5,366 个，排除了 7,060 个（垃圾/重复/恶意）

**安全选型标准**：评分 ≥ 4.0 + 下载量 > 1000 + 近3个月有更新 + 安装前审查代码

### 3.2 中文优化方向

| Skill | 说明 | 安装 |
|-------|------|------|
| **felo-search** | 支持中文/日文/韩文/英文的 AI 搜索，返回结构化答案+来源引用 | `clawhub install felo-search` |
| **a-share-real-time-data** | A 股实时行情数据（K线、报价、逐笔） | `clawhub install a-share-real-time-data` |
| **note-sync** | 多平台笔记同步（Mac备忘录/Notion/Obsidian/Evernote） | `clawhub install note-sync` |

### 3.3 自动化工作流方向

| Skill | 说明 | 安装 |
|-------|------|------|
| **n8n-workflow** | 自然语言控制 n8n 自动化实例，触发复杂工作流 | `clawhub install n8n-workflow` |
| **agent-team-orchestration** | 多 agent 团队编排，定义角色/任务生命周期/交接/审核 | `clawhub install agent-team-orchestration` |
| **automation-workflows** | 跨工具自动化流程设计（触发器/动作/重复任务） | `clawhub install automation-workflows` |
| **alex-session-wrap-up** | 会话结束时自动提交未推送工作、提取经验、持久化规则 | `clawhub install alex-session-wrap-up` |
| **deterministic-controller** | 确定性心跳/活动控制器 + sprint 模板 + cron 轮询 | `clawhub install deterministic-controller` |

### 3.4 代码审查方向

| Skill | 说明 | 安装 |
|-------|------|------|
| **github** | GitHub 集成（issues/PR/代码审查，自然语言操作） | `clawhub install github` |
| **developer-agent** | 协调 Cursor Agent，管理 git 工作流，确保代码质量 | `clawhub install developer-agent` |
| **arc-security-audit** | 全栈安全审计（skill 安全性） | `clawhub install arc-security-audit` |
| **arc-trust-verifier** | 验证 skill 来源可信度 + 信任评分 | `clawhub install arc-trust-verifier` |
| **auto-pr-merger** | 自动化 PR 合并工作流 | `clawhub install auto-pr-merger` |
| **publish-skill-vettr** | 静态分析安全审查 | `clawhub install publish-skill-vettr` |

### 3.5 知识管理方向

| Skill | 说明 | 安装 |
|-------|------|------|
| **2nd-brain** | 个人知识库，捕获/检索人物/地点/餐厅/游戏/技术信息 | `clawhub install 2nd-brain` |
| **principles** | Ray Dalio 式个人知识系统 | `clawhub install principles` |
| **note-sync** | 多平台笔记同步+版本控制+冲突解决 | `clawhub install note-sync` |
| **github-manager** | GitHub 项目分析/README 总结/代码结构理解/Star 追踪 | `clawhub install github-manager` |

### 3.6 综合推荐 TOP 10（非内置）

1. **web-browsing** — 基础能力，18万+安装
2. **felo-search** — 中文友好 AI 搜索
3. **n8n-workflow** — 自动化中枢
4. **github** — 代码工作流
5. **2nd-brain** — 知识管理
6. **developer-agent** — 开发助手
7. **agent-team-orchestration** — 多 agent 协作
8. **note-sync** — 笔记同步
9. **deterministic-controller** — 自动化控制
10. **alex-session-wrap-up** — 会话自动化

---

## 四、OpenClaw Node 节点功能详解

### 4.1 什么是 Node

Node 是运行在用户设备（iPhone/Mac/Android）上的原生应用，通过 WebSocket 连接到 OpenClaw Gateway，注册设备能力（摄像头、位置、麦克风、屏幕录制等），供 agent 通过 `node.invoke` RPC 调用。

**关键概念**：
- Node 是外设，不是 Gateway
- Telegram/WhatsApp 等消息落在 Gateway 上，不在 Node 上
- Node 必须在前台才能调用 canvas.* 和 camera.*

### 4.2 设备配对流程

#### macOS
```bash
# 1. 下载 macOS 客户端（GitHub releases）
# 2. 启动后输入 Gateway 地址和端口（默认 18789）
# 3. 同一局域网通常是 192.168.x.x:18789
# 4. 在 Gateway 端批准配对：
openclaw devices list              # 查看待配对设备
openclaw devices approve <id>      # 批准
openclaw devices reject <id>       # 拒绝
openclaw nodes status              # 查看已配对状态
```

#### iOS
1. 下载 iOS App（App Store）
2. 打开 → 自动发现局域网 Gateway（Bonjour 发现）
3. 输入配对码（或手动输入 Gateway IP）
4. Gateway 端批准
5. 功能：Canvas、语音唤醒、对话模式、摄像头、屏幕录制、设备配对

#### Android
1. 下载 Android App（GitHub releases / Play Store）
2. Connect Tab → 输入 setup code 或手动配置
3. Gateway 端批准
4. 功能：Canvas、摄像头、屏幕录制、聊天、语音

#### Headless Node（CLI 模式）
```bash
# 在远程机器上运行
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"

# 或安装为服务
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 4.3 各平台能力矩阵

| 能力 | macOS | iOS | Android |
|------|-------|-----|---------|
| Canvas（WebView） | ✅ | ✅ | ✅ |
| A2UI | ✅ | ✅ | ✅ |
| 摄像头拍照 | ✅ | ✅ | ✅ |
| 摄像头录像 | ✅ | ✅ | ✅ |
| 屏幕录制 | ✅ | ✅ | ✅ |
| 麦克风 | ✅ | ✅ | ✅ |
| 位置获取 | ✅ | ✅ | ✅ |
| 系统通知 | ✅ | ✅ | ✅ |
| 系统命令执行 (system.run) | ✅ | ❌ | ❌ |
| SSH 隧道远程连接 | ✅ | ❌ | ❌ |
| SMS 发送 | ❌ | ❌ | ✅ |
| 通讯录 | ❌ | ❌ | ✅ |
| 日历 | ❌ | ❌ | ✅ |
| 通话记录 | ❌ | ❌ | ✅ |
| 运动传感器 | ❌ | ❌ | ✅ |
| 语音唤醒 | ❌ | ✅ | ❌ |

### 4.4 常用命令速查

```bash
# === 摄像头 ===
openclaw nodes camera snap --node <id>                    # 双面拍照
openclaw nodes camera snap --node <id> --facing front      # 前置
openclaw nodes camera clip --node <id> --duration 10s      # 录像 10s

# === 屏幕录制 ===
openclaw nodes screen record --node <id> --duration 10s --fps 10
openclaw nodes screen record --node <id> --duration 10s --no-audio  # 无声

# === 位置 ===
openclaw nodes location get --node <id>
openclaw nodes location get --node <id> --accuracy precise --max-age 15000

# === Canvas ===
openclaw nodes canvas present --node <id> --target https://example.com
openclaw nodes canvas snapshot --node <id> --format png
openclaw nodes canvas eval --node <id> --js "document.title"

# === 通知 ===
openclaw nodes notify --node <id> --title "标题" --body "内容"

# === 远程执行 ===
openclaw nodes run --node <id> -- echo "hello"

# === Android 专属 ===
openclaw nodes invoke --node <id> --command sms.send --params '{"to":"+1xxx","message":"hi"}'
openclaw nodes invoke --node <id> --command contacts.search --params '{"query":"张三"}'
openclaw nodes invoke --node <id> --command calendar.events --params '{}'
```

### 4.5 注意事项

- **权限模型**：macOS 遵循 TCC（透明度、同意、控制），缺少权限时返回 `PERMISSION_MISSING`
- **屏幕录制限制**：最长 60 秒，Android 会弹出系统录制确认
- **位置默认关闭**：需在 Node 设置中手动启用
- **配对安全**：如果 Node 重试时 auth 变了，旧 requestId 会被替换，需重新查看 `devices list`
- **Exec 审批**：远程执行受 `~/.openclaw/exec-approvals.json` 控制，需要逐个 allowlist

---

## 五、关键发现总结

1. **ClawHub 是唯一官方 skill 注册表**（clawhub.ai），ClawdHub 是社区 fork，安全审计不足，建议慎用
2. **Skills 优先级**：workspace > ~/.openclaw/skills > 内置，同名覆盖机制清晰
3. **安全形势严峻**：13%+ 的 ClawHub skill 存在安全问题，安装前务必审查
4. **Node 是真正的多设备能力**：配合 iPhone/Android 可以实现拍照、定位、SMS 等手机原生能力
5. **中文生态已有起色**：felo-search、a-share-real-time-data 等中文优化 skill 可用
