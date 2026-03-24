---
name: execution-dispatcher
description: Translate strategy and analysis into delegated execution instructions for downstream operators, tools, or agents. Use when a judgment has already been made and the next step is to hand work to an execution layer with clear scope, guardrails, priorities, success criteria, and escalation conditions.
---

# Execution Dispatcher

Use this skill when the brain should assign work instead of doing everything itself.

## Core principle
Separate judgment from execution.
The brain decides direction, priority, and guardrails.
The execution layer handles concrete tasks.

## Dispatch workflow
1. State the mission in one sentence.
2. Define expected outcome.
3. Define scope and boundaries.
4. State priority order.
5. Define success criteria.
6. Define escalation triggers.
7. Hand off in compact, unambiguous language.

## Dispatch template
- 任务目标：
- 预期结果：
- 优先级：
- 边界：
- 不要做：
- 验收标准：
- 遇到这些情况立即上报：

## Rules
- Do not hand off vague intent.
- Do not mix analysis and execution in one messy block.
- Do not skip acceptance criteria.
- Preserve human approval for high-risk actions.

## Reference
Read `references/delegation-rules.md` for delegation quality control.
