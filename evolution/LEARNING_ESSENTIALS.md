# 学习精华 - 2026-03-19

## 一、OpenClaw 架构

### 主从模式
- **大脑（我）**：决策/设计/调度/分析
- **手脚（其他机器人）**：执行具体任务

### 技能系统
- 优先级：workspace > managed > bundled
- 安装：`clawhub install <skill>`

---

## 二、逆向工具栈（理解原理即可）

### 核心工具
| 工具 | 用途 | 官网 |
|------|------|------|
| Frida | Hook | frida.re |
| mitmproxy | 抓包 | mitmproxy.org |
| JADX | 反编译 | github.com/skylot/jadx |
| Ghidra | 二进制 | ghidra-sre.org |

### 实战流程
```
抓包 → 分析加密 → Hook还原 → 协议复现
```

---

## 三、Git 配置

```bash
git config --global http.proxy http://127.0.0.1:10808
git remote set-url origin https://user:token@github.com/user/repo.git
```

---

更新时间：2026-03-19

