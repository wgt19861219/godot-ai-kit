# godot-ai-kit Demo: 3D 收集物平台游戏

一个**中等复杂度** 3D demo,作为"活教材"演示套件四家协作:
- 第三人称角色控制(CharacterBody3D + 第三人称相机)
- 收集物玩法(拾取金币触发计分)
- 简单关卡(平台 + 收集点)

> **为什么 3D?** enhanced MCP 的 `dev_loop` 截图在 3D 场景下可靠(§6.4),
> 2D 截图已知短板见 `docs/enhanced-boundaries.md`。demo 选 3D 让"硬闭环验证"
> (运行→截图→断言)可在 polish/delivery 阶段真实跑通。

## 5 阶段产出物索引

套件工作流的 5 阶段产出物在此 demo 下落地:

| # | 阶段 | 文件 | MVP | v1 |
|---|------|------|-----|-----|
| ① | 概念(Concept) | [`docs/01-concept-gdd.md`](docs/01-concept-gdd.md) | **✅ 本 Task** | — |
| ② | 架构(Architecture) | [`docs/02-architecture-adr.md`](docs/02-architecture-adr.md)<br>[`scenes/player.tscn`](scenes/player.tscn) | **✅ 本 Task** | — |
| ③ | 生产(Production) | `docs/03-production.md` + `scenes/player.gd` | ❌ v1 | 可运行构建 |
| ④ | 打磨(Polish) | `docs/04-polish.md` + profiler 报告 | ❌ v1 | 性能达标 |
| ⑤ | 交付(Delivery) | `docs/05-delivery.md` + 发版包 | ❌ v1 | verify_delivery 通过 |

**MVP 范围(本 Task):** 只产出 ①②。③④⑤ 留给 v1(production 阶段才需要
enhanced `write_script`/`run_and_verify`,超出 Task 6 范围)。

## 演示的协作模式

- **load_skill(P0 无 stage):** ①② 两文档顶部都演示 `load_skill(query="...")`
  按需检索 gd-agentic 蓝图。**重要**: P0 返回的是 200 字符 `snippet` + `path`,
  需要蓝图全文时按 `path` 二次读取(详见各文档顶部说明)。
- **enhanced 协作:** `scenes/player.tscn` 是手写骨架(.tscn 文本),
  生产阶段可用 enhanced `add_node` + `save_scene` 重建更复杂的场景。

## 运行(③ 完成后)

```bash
# v1 完成生产阶段后:
godot --path demo scenes/Main.tscn
```

MVP 阶段 demo 不可运行(只有 ①② 文档 + player.tscn 骨架)。

---
*spec §6.4/§9 | plan2 Task 6 | 关联 `docs/enhanced-boundaries.md`*
