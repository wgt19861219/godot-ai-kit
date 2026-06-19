---
name: godot-area3d-collection
description: "Expert patterns for Area3D collection and pickup interactions in 3D: body_entered trigger, group-based identification via is_in_group, signal with sender parameter for dedup, connect vs hard-wire, Area3D as detection not blocking. Use for 3D collectibles, pickups, triggers, crystals, coins, items, 3D collection loops. Trigger keywords: Area3D, body_entered, collectible, pickup, collection, signal, is_in_group, queue_free, crystals, coins, items, trigger, NEVER."
---

# Area3D 收集交互实现

3D 收集物(Area3D)的实现模式:body_entered 触发 + 组优先判别 + signal 带 sender + 自销毁。
**不重复** `godot-physics-3d`(Area3D 只检测不阻挡、3D 物理层)与 `adapt-2d-to-3d`(Area2D→Area3D 转换矩阵)。

## NEVER Do

- **NEVER 用硬类型判断识别收集者** — `if body is CharacterBody3D` 过窄(NPC/载具/其他玩家拿不到,I3)。用**组优先** `body.is_in_group("player")`。
- **NEVER 发无参收集信号** — `signal collected` 无法区分多个收集物,主控无法去重(C2)。带 sender 参数 `signal collected(sender: Node)`,主控用 Set/Dict 按 sender 去重。
- **NEVER 硬连 body_entered 到外部方法** — 用 `body_entered.connect(_on_body_entered)`(节点生命周期安全;运行时动态 `instance` 的收集物可重连,硬连会漏)。
- **NEVER 用 Area3D 做阻挡** — Area3D 只做检测/触发。墙/屏障/边界用 `StaticBody3D` 保证立即、稳健的阻挡(引用 `godot-physics-3d`)。

## 2D→3D 迁移对照(精简)

| 维度 | Area2D | Area3D |
|---|---|---|
| 触发信号 | `body_entered(body: PhysicsBody2D)` | `body_entered(body: PhysicsBody3D)` |
| 监听空间 | `physics/2d` 层 | `physics/3d` 层(与 2D **独立**的系统,须重配 layer/mask) |
| 碰撞形状 | `Shape2D`(`BoxShape2D` 等) | `Shape3D`(`BoxShape3D` 等) |
| 机制 | body_entered / area_entered | **相同**(模式直接迁移) |

> 完整节点转换矩阵见 `adapt-2d-to-3d.md`。

## 示例脚本

### [pickup_trigger.gd](scripts/pickup_trigger.gd)
Area3D 收集触发:body_entered + 组优先 + signal 带 sender + queue_free。精简自 `demo/scenes/collectible.gd`(经 I3/C2 修复)。

## Common Gotchas

- **layer/mask 互补**:Area3D 与玩家 PhysicsBody3D 须在互补的 collision layer/mask 上,`body_entered` 才触发(3D 物理层独立于 2D,迁移时须重配)。
- **去重**:多收集物并发触发时,无参 signal 会让主控重复计分;signal 带 sender 主控方可按 sender 去重(C2)。
- **动态实例**:运行时 `instance` 的收集物(非场景树静态节点)须手动 `body_entered.connect` + 信号连主控,不依赖编辑器连线。

## Reference

- [`adapt-2d-to-3d`](../../../gd-agentic-skills/skills/godot-master/references/adapt-2d-to-3d.md) — Area2D→Area3D 转换、3D 物理层重配
- [`godot-physics-3d`](../../../gd-agentic-skills/skills/godot-physics-3d/SKILL.md) — Area3D 只检测不阻挡、3D collision layer/mask
- demo 实测:`demo/docs/03-production-log.md` F5/I3/C2(`:11,28,109-113`)
