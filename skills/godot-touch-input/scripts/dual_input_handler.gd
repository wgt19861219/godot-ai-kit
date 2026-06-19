## dual_input_handler.gd — 通用双兼容输入处理(移动触摸 + 桌面鼠标)
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## 修 C2(缺 InputEventMouseButton 分支 → 桌面/编辑器调试无法触发)
##   + M2(必检查 event.pressed,防双触发)。
## 信号接口(A2)解耦具体控件:消费者订阅信号,不关心 touch 还是 mouse 来源。
extends Node

# 触摸/点击发生(按下瞬间)。position 为事件坐标。
signal touch_occurred(position: Vector2)

# 拖拽增量。position 为当前坐标,relative 为相对上一帧的位移。
signal drag_delta(position: Vector2, relative: Vector2)

# 处理四类输入事件,统一为 touch/drag 两路信号。
# _input 在 GUI 之前调用(事件穿透 GUI),适合全局输入采集。
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		# M2 守卫:仅在 pressed==true 时发射,避免按下+释放双触发。
		if event.pressed:
			touch_occurred.emit(event.position)
	elif event is InputEventMouseButton:
		# C2 双兼容:桌面鼠标左键等价触摸,同样需 pressed 守卫(M2)。
		# 仅主键(左键);右键/中键等不等价触摸。
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			touch_occurred.emit(event.position)
	elif event is InputEventScreenDrag:
		drag_delta.emit(event.position, event.relative)
	elif event is InputEventMouseMotion:
		# MouseMotion 无 pressed 字段(它是移动事件,非按键事件)。
		# 用 Input 查询左键当前状态:仅在左键按住时才视为拖拽。
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			drag_delta.emit(event.position, event.relative)
