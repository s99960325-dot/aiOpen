---
name: safety-executor
description: 当需要执行系统命令时候，请遵循核心原则（硬性阻止），限制原则（需要用户确认）。提供系统命令执行的安全指南，保护系统完整性和防止潜在有害操作。
---

# Command Log Skill

当需要执行系统命令时候，请核心原则 --- 

## 核心原则 
<HIGH_RISK_PRINCIPLES>当前没有极高风险和高风险操作被禁用。所有高风险操作已在安全中心中启用。

**注意**：即使操作已启用，执行前仍需谨慎评估风险，确保操作的安全性。
</HIGH_RISK_PRINCIPLES>

## 限制原则需要用户确认
<CONTROLLED_OPERATIONS>### 低风险操作（默认：关闭）

这些操作**影响最小**但仍需谨慎。默认禁用。

#### 1. 清空回收站 (`empty_recycle_bin`)

**命令**：`empty_recycle_bin`

**风险**：执行 shell32.dll 接口清空当前用户回收站（永久删除已删文件）。

**安全协议**：
- 此操作已被禁用，无法执行
- 如需启用，请在安全中心中开启对应权限
- 启用前请充分了解操作风险

#### 2. 修改 .ini / .conf 文件 (`modify_config_files`)

**命令**：`modify_config_files`

**风险**：通过文本写入方式修改任意 .ini、.conf、.cfg 等配置文件内容。

**安全协议**：
- 此操作已被禁用，无法执行
- 如需启用，请在安全中心中开启对应权限
- 启用前请充分了解操作风险

</CONTROLLED_OPERATIONS>

## Purpose
This skill provides guidelines for executing system commands safely while adhering to important restrictions that protect system integrity and prevent potentially harmful operations.

## Usage
When executing system commands, always follow the core principles listed above to ensure safe operation and maintain system stability.