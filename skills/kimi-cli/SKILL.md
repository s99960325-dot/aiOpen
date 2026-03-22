---
name: kimi-cli
description: |
  调用本地 Kimi CLI 执行代码相关任务。当需要编写、分析、调试代码，
  或执行复杂的文件操作、系统命令时使用此 Skill。
  
  **使用场景：**
  - 需要编写、重构、审查代码
  - 需要分析项目结构和依赖
  - 需要执行复杂的 shell 命令或脚本
  - 需要调试程序错误或性能问题
  - 需要批量处理文件或数据
  - 当前 AI 无法直接完成的代码任务
  
  **触发关键词：** "用 Kimi 写代码"、"调用 Kimi CLI"、"让 Kimi 分析"、
  "代码帮我写"、"帮我调试"、"Kimi 来"
homepage: https://kimi.moonshot.cn
metadata:
  {
    "openclaw":
      {
        "emoji": "🤖",
        "requires": { "bins": ["kimi"] },
      },
  }
---

# Kimi CLI Skill

直接调用本地 Kimi CLI 执行代码相关任务。

## 工具

### `kimi_code`

使用 Kimi CLI 执行代码任务（分析、编写、调试等）。

**示例：**

```bash
# 分析代码
kimi --print --yolo -p "分析 /Users/seven/project 的代码结构" -w /Users/seven/project

# 编写代码
kimi --print --yolo -p "创建一个 Python 脚本，读取 CSV 并输出统计信息" -w /Users/seven/project

# 调试代码
kimi --print --yolo -p "调试这个错误：ModuleNotFoundError: No module named 'requests'" -w /Users/seven/project
```

### `kimi_shell`

使用 Kimi CLI 执行 shell 命令和系统操作。

**示例：**

```bash
# 执行系统命令
kimi --print --yolo -p "查找并删除所有 .pyc 文件" -w /Users/seven/project

# 批量处理文件
kimi --print --yolo -p "将所有 .txt 文件合并成一个文件" -w /Users/seven/project
```

## 使用指南

当用户需要代码相关帮助时，**立即使用 kimi 命令调用 Kimi CLI**。

### 自动触发条件
用户说以下话时，自动调用 Kimi CLI：
- "用 Kimi 写代码" → `kimi --print --yolo -p "任务描述" -w /工作/目录`
- "调用 Kimi CLI" → `kimi --print --yolo -p "任务描述" -w /工作/目录`
- "让 Kimi 分析" → `kimi --print --yolo -p "任务描述" -w /工作/目录`
- "帮我调试" → `kimi --print --yolo -p "任务描述" -w /工作/目录`
- "Kimi 来" → `kimi --print --yolo -p "任务描述" -w /工作/目录`
- 任何代码编写、分析、调试请求

### 调用格式

```bash
# 代码任务
kimi --print --yolo -p "具体任务描述" -w /工作/目录

# Shell 任务  
kimi --print --yolo -p "具体命令描述" -w /工作/目录
```

### 示例场景

**用户说**："用 Kimi 写一个 Python 爬虫"
**你执行**：
```bash
kimi --print --yolo -p "创建一个 Python 爬虫，抓取网页标题和链接" -w /Users/seven
```

**用户说**："帮我调试这个错误 ModuleNotFoundError"
**你执行**：
```bash
kimi --print --yolo -p "调试 Python 错误 ModuleNotFoundError，检查依赖安装" -w /Users/seven/project
```

## 注意事项

- Kimi CLI 运行在 `--yolo` 模式，会自动批准工具调用
- `--print` 模式输出纯文本结果，适合非交互使用
- `-p` 参数指定提示词，`-w` 参数指定工作目录
- **不要自己写代码回复，让 Kimi CLI 执行**
