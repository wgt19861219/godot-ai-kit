---
name: godot-touch-input
description: "Expert patterns for dual touch + mouse input handling in Godot 4: InputEventScreenTouch + InputEventMouseButton dual-compatibility branches, event.pressed guards against double-trigger, InputEventScreenDrag + InputEventMouseMotion drag equivalence, Camera2D pan with Vector2 zoom factor, two-finger pinch zoom with index tracking, mouse wheel zoom. Use for mobile touch, virtual joystick, camera pan, pinch zoom, desktop debug with mouse, mobile_input. Camera2D only. Trigger keywords: InputEventScreenTouch, InputEventScreenDrag, InputEventMouseButton, InputEventMouseMotion, virtual_joystick, pinch_zoom, camera_pan, touch, mobile_input, Vector2 zoom, event.pressed, NEVER."
---

# 触摸/鼠标双兼容输入实现(Camera2D)

移动触摸与桌面鼠标的等价输入处理:双兼容 `ScreenTouch+MouseButton` 分支、`event.pressed` 守卫、Camera2D Vector2 等比 pan/pinch。

> **Camera2D-only(A6)**:本 skill 脚本针对 `Camera2D`(有 `zoom: Vector2` 属性)。`Camera3D` 无 zoom,3D 场景须改 `fov`/`size`,另开 spec。

**clean room**:基于 Godot 4 官方 InputEvent 文档原创(disposal §5.2),非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。

## NEVER Do

- **NEVER touch 只处理 `InputEventScreenTouch` 不补 `InputEventMouseButton`** — 缺鼠标分支则桌面/编辑器调试无法触发(C2)。**必须双兼容**:`ScreenTouch`(移动)+ `MouseButton button_index==MOUSE_BUTTON_LEFT`(桌面)两条分支。
- **NEVER 不检查 `event.pressed`** — touch/mouse 事件 pressed=true(按下)与 pressed=false(抬起)都触发 `_input`,不守卫则**双触发**(M2)。按下分支须 `if event.pressed:`。
- **NEVER 用 `1.0/zoom.x` 单分量缩放** — zoom 是 `Vector2`,取 `.x` 单分量做 factor 会**非等比缩放偏移**(C3)。pan 与 pinch **都禁**:pan 用 `Vector2.ONE / camera.zoom`(Vector2 factor),pinch 用 `camera.zoom * ratio`(Vector2 乘)。
- **NEVER 生产 camera pan 用 `_input`** — `_input` 在 GUI 之前调用,**点 UI(暂停按钮)也触发 pan**(穿透)。生产 camera pan 建议 `_unhandled_input`(GUI 拦截后才到);示例脚本用 `_input` 简化,SKILL 此处明示权衡(S2)。

## 桌面鼠标 vs 移动触摸对照

| 操作 | 移动触摸 | 桌面鼠标(等价) |
|---|---|---|
| 按下 | `InputEventScreenTouch`(`pressed=true`) | `InputEventMouseButton`(`button_index=MOUSE_BUTTON_LEFT`,`pressed=true`) |
| 拖动 | `InputEventScreenDrag`(`relative: Vector2`) | `InputEventMouseMotion`(`relative`)+ `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` |
| 缩放 | 两指 pinch(`InputEventScreenTouch` `index` 0/1) | 鼠标滚轮(`MOUSE_BUTTON_WHEEL_UP`/`_DOWN`) |

> `InputEventScreenDrag` 只有 `position`/`relative`,**无 from**(A2)——拖动起点的回溯须消费者自己累积。

## 示例脚本

### [dual_input_handler.gd](scripts/dual_input_handler.gd)
通用双兼容 `_input` 模式:ScreenTouch+MouseButton 双分支 + `pressed` 守卫 + `touch_occurred`/`drag_delta` 信号接口(解耦具体控件)。修 C2(缺鼠标分支)+ M2(pressed 守卫)。

### [touch_camera_pan_zoom.gd](scripts/touch_camera_pan_zoom.gd)
Camera2D 平移 + 双指缩放 + 桌面滚轮。pan 用 `Vector2.ONE/zoom`(Vector2 factor),pinch 两指 `index` 0/1 据距离比 `zoom=start_zoom*ratio`(等比)。修 C3(zoom.x 单分量)+ M3(Vector2 factor 钉死)。

## Common Gotchas(headless 测不出,只有真机才发现)

- **headless 测不出真实触摸**:触屏硬件事件只有真机/模拟器产生;headless 只能构造 `InputEvent` 实例验**逻辑分支**(pressed 守卫 / 双兼容 / Vector2 factor),**手感/惯性须真机人工**。
- **`_input` 穿透**:点 UI 按钮(暂停/菜单)会先经 `_input` 再到 GUI → camera pan 误触发。生产用 `_unhandled_input`(S2)。
- **mouse drag 无 pressed 字段**:`InputEventMouseMotion` 不带 pressed,须查 `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` 判断是否拖动中。
- **MouseMotion 桌面 drag 真机覆盖**(review Minor 3):`Input` 单例难在 headless 注入,MouseMotion 分支(drag 桌面半边)无 headless 正向测试 → 须**真机覆盖**。`test/dual_input_handler_test.gd` 覆盖 touch/mouse 按下 + ScreenDrag,MouseMotion 真机补。
- **同点落指吞 pinch**(review Minor 2):`_pinch_start_dist == 0`(两指同点,合法)时防除零守卫**静默吞 pinch** —— 用户须分开两指重落。生产可加最小指距阈值提示。
- **Camera2D-only**:Camera3D 无 `zoom`,3D 须改 `fov`/`size`(A6,另开 spec)。
- **Godot 4.7 device ID 变更**:4.7 起 mouse/keyboard 的 `InputEvent.device` 从 `0` 改为 `InputEvent.DEVICE_ID_MOUSE`(32)/`DEVICE_ID_KEYBOARD`(16)(GH-116274)。本 skill 按事件**类型**(`event is InputEventScreenTouch` 等)判断,不依赖 `device==0`,**不受影响**;若你的代码靠 `device==0` 判鼠标,4.7 须改用类型判断或常量。

## Reference

- Godot 4 官方 InputEvent 文档(唯一事实来源,clean room):`https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html`
- 输入事件处理顺序(官方):`_input`(GUI 前)→ GUI `_gui_input` → `_unhandled_input`(GUI 后);gameplay 输入官方推荐 `_unhandled_input`(允许 GUI 拦截)
