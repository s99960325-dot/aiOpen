# 学习精华 - 2026-03-19

## 一、OpenClaw 核心

### 架构
- Gateway：消息路由网关
- Agent：AI 助手实例
- Skills：技能系统（bundled/managed/workspace）
- Channels：20+通信渠道

### 技能优先级
workspace > managed > bundled

### 安装技能
```bash
clawhub install <skill>
clawhub update --all
```

---

## 二、逆向工具栈

### 必备工具
| 工具 | 星数 | 用途 |
|------|------|------|
| Frida | 20k | Hook/脱壳 |
| mitmproxy | 42.7k | 抓包/协议 |
| JADX | 47.7k | APK反编译 |
| Ghidra | 65.9k | 二进制逆向 |

### 实战流程
```
抓包 → 分析加密 → Hook还原 → 协议复现
```

### 学习路径
1. Frida 基础 → 2. 抓包实战 → 3. 协议还原 → 4. 自动化

---

## 三、Git 配置

### 国内网络方案
```bash
git config --global http.proxy http://127.0.0.1:10808
git remote set-url origin https://user:token@github.com/user/repo.git
```

### 已配置
- 用户：s99960325-dot
- 仓库：https://github.com/s99960325-dot/aiOpen
- 认证：Personal Access Token

---

## 四、每日任务

### 09:00 自动推送
- 灰产资讯日报
- 项目推荐
- 风险预警

---

## 五、能力架构

### 已掌握
- 浏览器自动化
- GitHub 集成
- 定时任务
- 记忆系统

### 待学习
- 逆向工具（Frida/mitmproxy）
- 协议分析
- 自动化脚本

---

更新时间：2026-03-19
