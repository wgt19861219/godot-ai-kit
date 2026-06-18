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
| ③ | 生产(Production) | [`docs/03-production-log.md`](docs/03-production-log.md)<br>`scenes/{player,main,collectible}.gd` + `Main.tscn` | ✅ 可运行 | — |
| ④ | 打磨(Polish) | 性能/profiler 实质工作并入 [`03-production-log.md`](docs/03-production-log.md) T6 | ✅(并入③) | — |
| ⑤ | 交付(Delivery) | 交付核对 + CRLF 治理并入 [`03-production-log.md`](docs/03-production-log.md) T7 | ✅(并入③) | — |

**dogfood 范围:** ①②③④⑤ 全程双轨对照完成,产出 3 篇文档(①②③)+ 可运行 demo。
④⑤ 的性能与交付核对实质工作并入 [`03-production-log.md`](docs/03-production-log.md) T6/T7,未单独成文。

## 演示的协作模式

- **load_skill(P0 无 stage):** ①② 两文档顶部都演示 `load_skill(query="...")`
  按需检索 gd-agentic 蓝图。**重要**: P0 返回的是 200 字符 `snippet` + `path`,
  需要蓝图全文时按 `path` 二次读取(详见各文档顶部说明)。
- **enhanced 协作:** `scenes/player.tscn` 是手写骨架(.tscn 文本),
  生产阶段可用 enhanced `add_node` + `save_scene` 重建更复杂的场景。

## 运行

```bash
godot --path demo scenes/Main.tscn
# 或直接 godot --path demo(project.godot 已设 main_scene=Main.tscn)
```

操作:**W/A/S/D** 移动、**Space** 跳跃,碰水晶计分,集齐 3 颗显示 "Clear!"。
(输入映射见 `project.godot` 的 `[input]` 段——demo 用自定义 `move_*` action 绑 WASD,
不复用 `ui_*`,避免与 UI 导航耦合。**未绑方向键**:GDD(`01-concept-gdd.md`)只要求 WASD,
故按方案 B 仅做 WASD 作为"游戏 action 与 UI action 分离"的活教材;如需方向键共存,可在 `[input]` 段把 `ui_up/down/left/right` 追加方向键事件。)

---
*spec §6.4/§9 | plan2 Task 6 | 关联 `docs/enhanced-boundaries.md`*
