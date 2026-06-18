# 贡献指南 — godot-ai-kit

## 套件架构(贡献前必读)

godot-ai-kit 是 LGPLv3 **真聚合**套件:粘合层(`CLAUDE.md`/`rules`/`workflow`/`install`/`demo`/`docs`/`config`)只**指针引用** 3 个独立子模块,不复制或改写知识源文件。这条红线决定每个子模块的贡献方式。

## 子模块改动规则

| 子模块 | 许可 | 套件层能否改其源 | 贡献方式 |
|--------|------|------------------|----------|
| `enhanced/` | MIT(wgt) | ✅ 可改 | 改 src → `npm run build` → 套件更新 pin |
| `GodotPrompter/` | MIT(jame581) | ⚠️ 只在子模块内改 | 到 GodotPrompter 上游改,套件 pin 更新(贡献规则见其 `CLAUDE.md`) |
| `gd-agentic-skills/` | LGPLv3(thedivergentai) | ❌ **绝不改源** | 只通过 `load_skill(query)` 引用;改动需求提上游 |

### enhanced 改动流程(MIT,本仓库维护)

1. 在 enhanced 子模块或 `godot-mcp-enhanced` 主线改 `src/`
2. `cd enhanced && npm run build`(`build/` 是 gitignore 构建产物)
3. enhanced 仓 commit + `git push origin`
4. 套件主仓 `git add enhanced` 更新 pin + commit

### gd-agentic-skills 红线

套件粘合层**绝不修改其源文件**(避免 LGPLv3 派生义务)。只 `load_skill(query=...)` 按需引用其内容。详见 `NOTICE` 与 `docs/compatibility-matrix.md`。

## 粘合层贡献

`CLAUDE.md` / `rules` / `workflow` / `install` / `demo` / `docs` / `config` 的改动直接在套件主仓提 PR:

- 遵循现有风格:中文注释、**绝对路径**引用、Obsidian callout 分区
- token 预算:`CLAUDE.md` ≤ 4KB,`rules/` ≤ 8KB(超限下沉 `load_skill`,见 `rules/budget-guard.md`)
- 改 `install.ps1` / `install.sh` 后双端必须等价(README 宣称"等价"需真实)

## 工作流阶段

套件用 **6 阶段循环工作流**(`1-design`/`2-develop`/`3-verify`/`4-complete`/`5-archive` + README 流转图,见 `workflow/README.md` + `docs/superpowers/specs/2026-06-18-workflow-loop-restructure-design.md`)。涉及 `workflow/` 的贡献按 6 阶段结构。

## 提交规范

- message:`type(scope): 描述`(`type`: feat/fix/docs/refactor/chore;`scope`: demo/enhanced/bridge/workflow 等)
- 协作结尾 `Co-Authored-By`
- 引用文件用**绝对路径**(见全局 CLAUDE.md 路径规范)

## 验证

- 改 enhanced 源后:`cd enhanced && npm run build && npm test`(~950 用例)
- 改 demo 后:`godot --path demo scenes/Main.tscn` 实跑(2D 截图 headless 不可用,关键视觉人工验)
- 发版前:`.\install.ps1` 自检 + `verify_delivery`
