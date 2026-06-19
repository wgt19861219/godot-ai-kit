---
name: godot-characterbody-3d
description: "Expert patterns for CharacterBody3D player controllers in 3D: camera-relative movement via spring arm basis, breaking transform.basis feedback loops, horizontal-plane projection, delta-normalized deceleration, WASD InputMap binding, gravity and jump. Use for 3D player characters, third-person controllers, 3D platformer or shooter movement. Trigger keywords: CharacterBody3D, move_and_slide, is_on_floor, velocity, spring_arm, camera_relative, movement, WASD, InputMap, third_person, 3d player controller, gravity, jump, NEVER."
---

# CharacterBody3D 3D 玩法实现

3D 玩家控制器的实现细节:相机相对移动、断反馈循环、水平面投影、delta 归一 decel、WASD InputMap。
**不重复** `godot-physics-3d`(RigidBody/物理层/楼梯检测)与 `adapt-2d-to-3d`(节点转换矩阵/迁移步骤)——本 skill 只管"3D 玩法实现细节"。

## NEVER Do

- **NEVER 用移动方向乘自身 basis** — `transform.basis * input_dir` 配合旋转改朝向会形成**反馈循环**(W 自洽不抖、A/S/D 振荡闪烁,F15)。方向取**相机臂 basis**(`spring_arm.global_transform.basis`),Player 根与 mesh 全程不转。
- **NEVER 跳过水平面投影直接归一** — 方向向量须先 `direction.y = 0` 投影水平面再 `normalized()`,否则相机俯仰时斜向加速。
- **NEVER 写帧率敏感的减速** — decel 必须 delta 归一:`var decel := SPEED * DECEL * delta`,`move_toward(velocity.x, 0.0, decel)`(I2)。裸 `move_toward(velocity.x, 0, SPEED)` 帧率敏感。
- **NEVER 假设 WASD 默认绑定** — Godot 4 默认 InputMap **不绑 WASD**(只方向键 + 手柄 D-Pad,F14)。须在 `project.godot` `[input]` 段用 `physical_keycode` 显式定义 `move_forward(W=87)`/`move_back(S=83)`/`move_left(A=65)`/`move_right(D=68)`。
- **NEVER 旋转 Player 根做相机跟随** — 鼠标 yaw/pitch 只旋转 `SpringArm3D`,Player 根不动;否则相机跟着角色转 → 视角乱、二次切方向无效(F16)。朝向变化用 `lerp_angle` 平滑作用于 mesh,不瞬转。

## 2D→3D 迁移对照(精简)

| 维度 | CharacterBody2D | CharacterBody3D |
|---|---|---|
| 输入向量 | `Input.get_vector`(Vector2,x/y) | 同 API,映射到 x/z 平面 |
| 方向空间 | 世界或自身 basis | **相机臂 basis**(第三人称);世界坐标是 F15 中间态 |
| 重力轴 | `velocity.y += gravity*delta`(2D y 向下) | `velocity.y -= gravity*delta`(3D,JUMP 正值向上) |
| 楼梯/坡 | `floor_snap_length` | 引用 `physics-3d` 的 ShapeCast3D 楼梯逻辑 |

> 完整节点转换矩阵(`CharacterBody2D`→`CharacterBody3D` 等)见 `adapt-2d-to-3d.md`。

## 示例脚本

### [camera_relative_movement.gd](scripts/camera_relative_movement.gd)
3D 第三人称玩家控制器:相机臂 basis 取向 + 水平面投影 + delta 归一 decel。精简自 `demo/scenes/player.gd`(经 F14–F16 实测修复 + WASD 人工实测)。

## Common Gotchas(headless 测不出,只有真机才发现)

- **缺光源**:3D 场景无 `DirectionalLight3D`/`WorldEnvironment` 时画面全黑(F14)。headless 截图"渲染正常"常是误判 —— 色调暗未细看。
- **反馈循环**:`transform.basis*input` + `look_at` 改朝向 = A/S/D 闪烁(F15),只有真机按键才暴露,headless 完全无法复现。
- **WASD 默认不绑**:Godot 4 InputMap 不含 WASD(F14),headless 测"输入响应"是盲区;InputMap 绑定可 `execute_gdscript` 读 InputMap 验证,但**按键实际响应须人工**。

## Reference

- [`adapt-2d-to-3d`](../../../gd-agentic-skills/skills/godot-master/references/adapt-2d-to-3d.md) — 节点转换矩阵、迁移步骤(迁移源头)
- [`godot-physics-3d`](../../../gd-agentic-skills/skills/godot-physics-3d/SKILL.md) — RigidBody vs CharacterBody 选择、ShapeCast3D 楼梯检测
- demo 实测:`demo/docs/03-production-log.md` F14/F15/F16(`:176-192`)
