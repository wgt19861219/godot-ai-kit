# workflow/ 循环式重组设计

> 日期:2026-06-18
> 状态:已实施(2026-06-18,用户决定从"发布后"提前到"发布前"执行)
> 范围:套件 `workflow/` 从线性 5 阶段升级为 **6 阶段循环(5 编号目录 + README)**

## 背景

当前 `workflow/` 线性 5 阶段(`concept`/`architecture`/`production`/`polish`/`delivery`)。借鉴 `Claude-Code-Game-Studios` 目录组织,升级为**循环式**:设计→开发→验证→完成→归档→回设计(下一轮),支撑迭代开发。

## 设计

### 目录结构(6 循环节点 = 5 编号目录 + README 流转图)

```
workflow/
├── README.md       ← 循环导航 + 流转图(design→develop→verify→complete→archive→回 design)
├── 1-design/       ← 设计(← concept + architecture):GDD/蓝图/ADR
├── 2-develop/      ← 开发(← production):NEVER 规则/构建
├── 3-verify/       ← 验证(← polish 全量):① 验证(测试/验收/性能验收) ② 优化提升(polish 优化) + fix 子章节(debug)
├── 4-complete/     ← 完成(← delivery):审查/发版
└── 5-archive/      ← 归档(新):轮次 GDD/log 快照 + demo 版本归档
```

循环节点 6 个(`design`/`develop`/`verify`/`complete`/`archive`/`loop`)。`fix` 并入 `3-verify` 子章节、`loop` 并入 README 流转图 → 5 编号目录 + README。

### 迁移映射

| 当前 | 新位置 |
|------|--------|
| `workflow/concept.md` | `workflow/1-design/` |
| `workflow/architecture.md` | `workflow/1-design/` |
| `workflow/production.md` | `workflow/2-develop/` |
| `workflow/polish.md` | `workflow/3-verify/`(**全量**;内部分 ① 验证 ② 优化提升) |
| `workflow/delivery.md` | `workflow/4-complete/` |
| (无) | `workflow/5-archive/`(新增) |
| (无) | fix → `3-verify/` 子章节(等真实调试经验再拆独立目录) |
| (无) | loop → README 流转图尾端(不单建 `_loop.md`) |

### 决策(含第 1 轮审查结论)

1. 阶段用**目录**(非单文件)✓
2. `5-archive/` 放**两者**(轮次 GDD/log 快照 + demo 版本归档)✓
3. **编号前缀 + 重编号去断层**(原 5-complete→4,原 6-archive→5)✓
4. polish **全量**入 `3-verify/`(①验证 ②优化提升 分节,不拆)— 审查 (a) 的 `3-optimize` 否决,守住循环 verify 语义 ✓
5. fix 并入 `3-verify` 子章节,**不建 `4-fix/`**(避免空壳,YAGNI)— 审查 (d) ✓
6. loop 并入 README 流转图,**不单建 `_loop.md`**(职责不重叠 + 结构一致)— 审查 (c) ✓
7. `demo/docs/01-03` 编号**保留**(dogfood 成品快照),`demo/README.md` 补历史说明 — 额外1 ✓

## 影响范围

- `workflow/` 路径全变,更新引用:`CLAUDE.md`(5 处路径 + "5 阶段"→"6 阶段循环")、`README.md`、`workflow/README.md`(重写)、`demo/docs/03-production-log.md`
- **enhanced 子模块悬空引用**(审查 b):`enhanced/docs` 的 design spec + mvp plan 引用 `workflow/*.md`(6 处),重组后悬空。按 LGPLv3 真聚合 + YAGNI,**历史 docs 不追改**,在 `UPGRADING.md` 注明"套件 workflow/ 已升级 6 阶段循环,enhanced 历史文档保留旧 5 阶段引用"。
- `demo/docs/01-03` 编号**保留**(成品快照,改编号会伪造"demo 用了 7 阶段"假象,违背诚实化),`demo/README.md` 补"本 demo 基于历史 5 阶段制作,套件已升级 6 阶段循环"。

## 不做(YAGNI)

- 不改 3 子模块源(enhanced/GodotPrompter/gd-agentic-skills)
- 不引入 agent 工作室结构
- `docs/` 分层、`registry/` 为后续打磨
- 发布标配(CONTRIBUTING/SECURITY/UPGRADING)拆为独立 spec(见 `2026-06-18-release-essentials-design.md`),不混入本 spec

## 时机

**已实施**(2026-06-18,用户决定提前到发布前执行;原计划发布后,审查通过后用户改主意)。发布版现已含 6 阶段循环结构。
