# OpenClaw 学习精华 - 2026-03-19

## 一、OpenClaw 核心架构

### 定位
- 个人 AI 助手网关，运行在自己的设备上
- 一个 Gateway 进程连接多个聊天渠道
- 模型无关，支持 OpenAI/Anthropic/GLM 等多家 API

### 支持的渠道（20+）
WhatsApp, Telegram, Discord, Slack, Google Chat, Signal, iMessage, BlueBubbles, IRC, Microsoft Teams, Matrix, Feishu, LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, WebChat

### 核心组件
- **Gateway**: 控制平面，处理消息路由
- **Agent**: 实际的 AI 助手
- **Skills**: 技能系统，教会助手使用工具
- **Channels**: 通信渠道插件

---

## 二、技能系统（AgentSkills）

### 三层架构
1. **Bundled skills** - 随安装包附带（优先级最低）
2. **Managed skills** - `~/.openclaw/skills`（所有 agent 共享）
3. **Workspace skills** - `<workspace>/skills`（优先级最高）

### 技能格式
```markdown
---
name: skill-name
description: 技能描述
homepage: https://example.com
metadata: {"clawdbot":{"requires":{"bins":["tool"]}}}
---

# 使用说明
具体指导内容...
```

### 安装技能
```bash
# 从 ClawHub 安装
clawhub install <skill-slug>

# 更新所有技能
clawhub update --all
```

### 技能市场
- **ClawHub**: https://clawhub.com
- 浏览、安装、发布技能
- 版本管理（类似 npm）

---

## 三、已安装的核心技能

### 灰产相关
1. **bird** - X/Twitter 操作（cookie 认证，发推/搜索/互动）
2. **peekaboo** - macOS UI 自动化（截图/控制界面）
3. **himalaya** - 多账户邮件管理
4. **wacli** - WhatsApp 操作
5. **imsg** - iMessage 聊天记录管理
6. **slack** - Slack 频道操作

### 工具类
- **mcporter** - MCP 服务器管理工具
- **coding-agent** - 自动写代码
- **1password** - 密码管理
- **tmux** - 后台交互式任务
- **session-logs** - 查看自己会话日志

---

## 四、浏览器工具

### 启动方式
```bash
# 启动浏览器
browser action=start profile=clawd

# 导航
browser action=navigate targetUrl=https://example.com

# 抓取页面
browser action=act request={"kind":"evaluate","fn":"document.body.innerText"}
```

### 已验证能力
- 打开任意网站
- 提取页面内容
- 自动化操作（点击/输入）
- 不需要 API key 即可搜索

---

## 五、Git/GitHub 配置

### 解决国内网络问题
**方案：HTTPS + 代理**
```bash
# 配置代理
git config --global http.proxy http://127.0.0.1:10808
git config --global https.proxy http://127.0.0.1:10808

# 配置 GitHub token
git remote set-url origin https://user:token@github.com/user/repo.git
```

### 已配置
- 用户：s99960325-dot
- 仓库：https://github.com/s99960325-dot/aiOpen
- 认证：Personal Access Token
- 代理：127.0.0.1:10808

---

## 六、定时任务（Cron）

### 创建任务
```json
{
  "name": "task-name",
  "schedule": {"kind": "every", "everyMs": 3600000},
  "payload": {"kind": "agentTurn", "message": "任务内容"},
  "sessionTarget": "isolated",
  "enabled": true
}
```

### 已部署
- 每小时检查 workspace 更新
- 自动提交推送到 GitHub

---

## 七、进化体系

### 目录结构
```
evolution/
├── lessons/      # 教训记录
├── patterns/     # 模式识别
├── evals/        # 评分系统
└── prompts/      # 提示词迭代
```

### 运行机制
- 每次心跳检查 HEARTBEAT.md
- 被纠正时记录到 lessons/
- 重复模式达到3次自动化
- 每周日执行进化任务

---

## 八、关键配置文件

| 文件 | 作用 |
|------|------|
| SOUL.md | 性格定义 |
| IDENTITY.md | 身份标识 |
| USER.md | 主人档案 |
| AGENTS.md | 运行规则 |
| MEMORY.md | 长期记忆 |
| HEARTBEAT.md | 自检清单 |
| evolution/SELF_EVOLUTION.md | 进化日志 |

---

## 九、待优化项

1. **搜索速度** - 浏览器比 API 慢，可考虑 Brave Search API
2. **内存管理** - 8GB 偏紧，需定期清理后台进程
3. **SSH 代理** - macOS nc 不支持 HTTP 代理，需额外工具

---

## 十、重要链接

- **文档**: https://docs.openclaw.ai
- **文档索引**: https://docs.openclaw.ai/llms.txt
- **GitHub**: https://github.com/openclaw/openclaw
- **技能市场**: https://clawhub.com
- **Discord**: https://discord.gg/clawd
- **社区**: https://clawd.bot

---

提取时间：2026-03-19 08:31
