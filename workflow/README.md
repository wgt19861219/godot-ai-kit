# 开发循环 — 6 阶段

套件用循环式工作流指导 Godot 游戏开发:每一轮按 6 阶段流转,归档后回到设计开启下一轮。

## 流转图

```
1-design  →  2-develop  →  3-verify  →  4-complete  →  5-archive
   ↑                                                         │
   └───────────────────  下一轮迭代  ←────────────────────────┘
```

## 阶段

| 阶段 | 目录 | 目标 | 来源 |
|------|------|------|------|
| 1 设计 | `1-design/` | 概念→蓝图→GDD→ADR | `concept.md` + `architecture.md` |
| 2 开发 | `2-develop/` | NEVER 规则→可运行构建 | `production.md` |
| 3 验证 | `3-verify/` | ① 验证(测试/验收/性能验收) ② 优化提升(polish) + fix 子章节(debug) | `polish.md`(全量) |
| 4 完成 | `4-complete/` | 审查清单→发版 | `delivery.md` |
| 5 归档 | `5-archive/` | 轮次 GDD/log 快照 + demo 版本归档 | 新增 |

## 迭代

完成一轮(归档后),回到 `1-design/` 开启下一轮。归档产物是下一轮的基线参考。

## 硬闭环诚实化

每阶段**约定调用 enhanced 验证工具 + 阶段门禁**(AI 遵守约定 + 文档要求贴验证结果)。enhanced 工具能验证、不能阻止跳阶段。详见各阶段文档。

## 历史

本循环由线性 5 阶段(`concept`/`architecture`/`production`/`polish`/`delivery`)升级而来(2026-06-18,见 `docs/superpowers/specs/2026-06-18-workflow-loop-restructure-design.md`)。
