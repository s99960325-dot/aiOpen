---
name: case-finder
description: Find and extract useful cases, analogies, precedents, and comparable examples from local knowledge, memory, notes, or the web. Use when the user asks for examples, precedents, benchmarks, proof points, similar projects, or wants evidence-backed pattern matching before making a decision.
---

# Case Finder

Use this skill to support judgment with examples instead of empty opinion.

## Retrieval order
1. Check core local files and memory first.
2. Check notes or knowledge-base sources.
3. Search the web only when local evidence is weak.
4. Prefer concrete comparable cases over generic articles.

## Extraction rules
For each case, try to capture:
- Case name / type
- What happened
- Why it worked or failed
- What is transferable
- What is not transferable

## Output style
- 先给总体结论
- 再列 2-5 个最像的案例
- 最后说对当前问题的启发

## Reference
Read `references/comparison-rules.md` when the user needs analogies, benchmarks, or proof-backed support.
