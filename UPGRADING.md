# 升级说明 — godot-ai-kit

## enhanced 子模块更新

套件 `enhanced` pin 指向 `godot-mcp-enhanced` 的某 commit。更新到主线最新:

```bash
git submodule update --remote enhanced    # 拉主线最新
cd enhanced && npm run build               # 重建 build/(gitignore 产物)
cd .. && git add enhanced && git commit -m "chore(submodule): 更新 enhanced"
```

外部 clone 后:`git submodule update --init`(要求 enhanced pin 在 origin 可达,见 `docs/compatibility-matrix.md` C1 脚注)。

## Godot 4.6+ Bridge 修复

Godot **4.6.2 收紧 GDScript**:`extends Node`(原生类)的虚函数 `_ready`/`_exit_tree` 调 `super()` 报 Parse error(`Cannot call the parent class' virtual function ... hasn't been defined`),导致脚本加载失败、autoload 崩、Bridge 连不上。

已在 enhanced `f7cab67` 修复(删两处 `super()`,IMP-4 lifecycle convention 仅适用于 extends 自定义基类)。**4.4/4.5 不受影响**。升级 enhanced 到含 `f7cab67` 的版本即可。

## workflow/ 重组(前瞻 — 发布后执行)

> ⚠️ 本节为**前瞻说明**。当前发布版 workflow/ 仍是 5 阶段;以下变更将在**发布后**首个迭代执行。

**当前**:workflow/ 线性 5 阶段(`concept`/`architecture`/`production`/`polish`/`delivery`)。

**发布后将升级**为 6 阶段循环(见 `docs/superpowers/specs/2026-06-18-workflow-loop-restructure-design.md`):

```
workflow/  →  README.md(循环流转图) + 1-design/ 2-develop/ 3-verify/ 4-complete/ 5-archive/
```

升级影响:
- 套件引用更新:`CLAUDE.md`("5 阶段"→"6 阶段循环")、`README.md`、`demo/docs` 引用 `workflow/*.md` 处、`CONTRIBUTING.md` 过渡说明
- **enhanced 历史文档将悬空**(前瞻):enhanced/docs 的 design spec + mvp plan 引用旧 `workflow/*.md`,重组后成悬空引用。按 LGPLv3 真聚合 + YAGNI,**历史 docs 不追改**,保留旧引用作为历史记录(本文件即该说明的落点)。

升级时机:发布后第一件事(发布版内容**不依赖**重组后结构)。

## 发布标配文档

`CONTRIBUTING.md` / `SECURITY.md` / `UPGRADING.md` 随版本更新。本文件记录每个版本的不兼容变更 + 迁移指引。
