# 发布标配文档设计(CONTRIBUTING / SECURITY / UPGRADING)

> 日期:2026-06-18
> 状态:待审查
> 范围:补齐开源发布标配文件(与 workflow 重组**独立**的两件事,分两次 commit)

## 背景

借鉴 `Claude-Code-Game-Studios`,godot-ai-kit 当前缺开源发布标配。发布前补齐。从 workflow 重组 spec 拆出(审查额外2:避免 blast radius 放大)。

## 设计

新增 3 文件(顶层):

| 文件 | 内容 |
|------|------|
| `CONTRIBUTING.md` | 贡献流程:子模块改动规则(enhanced MIT 可改 / gd-agentic-skills LGPLv3 真聚合不改源)、PR 规范、5→6 阶段过渡期说明 |
| `SECURITY.md` | 安全策略:enhanced bridge 本地 TCP(127.0.0.1)+ secret 权限收紧、漏洞报告渠道 |
| `UPGRADING.md` | 升级说明:enhanced pin 更新方式、workflow 重组(发布后)引用迁移指引、**enhanced 历史文档悬空引用说明**(见 workflow-loop-restructure spec) |

## 与 workflow 重组的关系

两件事独立:
- **本 spec**(发布标配):发布**前**做(CONTRIBUTING/SECURITY 是发布硬缺口)
- **workflow 重组 spec**:发布**后**做(避免发布期改结构)

`UPGRADING.md` 会引用 workflow 重组的悬空引用说明,但两 spec 独立 commit。
