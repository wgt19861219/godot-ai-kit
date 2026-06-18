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

## workflow/ 重组(已实施 — 2026-06-18)

套件 `workflow/` 已从线性 5 阶段升级为 6 阶段循环:`README.md`(流转图) + `1-design/` `2-develop/` `3-verify/` `4-complete/` `5-archive/`(见 `docs/superpowers/specs/2026-06-18-workflow-loop-restructure-design.md`)。

升级影响(已落地):
- 套件引用已更新:`CLAUDE.md`、`README.md`、`workflow/README.md`、`demo/README.md`(补历史说明)
- **enhanced 历史文档悬空**:`enhanced/docs` 的 design spec + mvp plan 引用旧 `workflow/*.md`,重组后悬空。按 LGPLv3 真聚合 + YAGNI,**历史 docs 不追改**,保留旧引用作为历史记录(本条即该说明的落点)。
- `demo/docs/01-03` 编号保留(dogfood 成品快照),`demo/README.md` 已补历史说明。

## 发布标配文档

`CONTRIBUTING.md` / `SECURITY.md` / `UPGRADING.md` 随版本更新。本文件记录每个版本的不兼容变更 + 迁移指引。
