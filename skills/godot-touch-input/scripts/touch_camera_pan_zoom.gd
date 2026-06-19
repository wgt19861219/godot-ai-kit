## touch_camera_pan_zoom.gd — Camera2D 平移 + 双指缩放 + 桌面滚轮
## 基于 Godot 4 官方 InputEvent 文档原创(clean room,disposal §5.2),
## 非 gd-agentic 派生;实现 agent 未接触 gd-agentic adapt-desktop-to-mobile 原文。
## 官方文档:https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
##
## Camera2D-only(A6):Camera2D 有 zoom(Vector2);Camera3D 无 zoom,3D 须改 fov/size,另开 spec。
## 修 C3(zoom.x 单分量 → 非等比缩放偏移)+ M3(pan factor 钉死 Vector2,pan/pinch 都禁 1.0/zoom.x)。
extends Node

# 消费者注入目标相机。Camera2D 有 zoom(Vector2)与 offset(Vector2),Camera3D 无 zoom(A6)。
@export var camera: Camera2D

# pinch 状态:index(int,InputEventScreenTouch/Drag.index)→ position(Vector2)。
var _pinch: Dictionary = {}
# 两指就位瞬间记录:起始指距与起始 zoom,后续据比值等比缩放。
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: Vector2 = Vector2.ONE

# zoom 各分量 clamp 范围(C3 等比:两分量同范围,不拆分单分量)。
const _MIN_ZOOM := 0.1
const _MAX_ZOOM := 10.0

# 桌面滚轮每格缩放倍数。
const _WHEEL_STEP := 1.1

# 平移:相对位移按 zoom 反比折算到世界坐标。
# M3 铁律:factor 必为 Vector2.ONE/camera.zoom(逐分量除),
# 严禁 1.0/zoom.x 单分量 —— 那会在非等比 zoom 下产生方向偏移(C3)。
func _apply_pan(relative: Vector2) -> void:
	var factor: Vector2 = Vector2.ONE / camera.zoom
	camera.offset -= relative * factor

# 缩放并 clamp:Vector2.clamp 逐分量 clamp,两分量共用同范围,保等比(C3)。
# 不读取 zoom.x/zoom.y 单分量,避免被误用为 factor(M3 反向自检)。
func _set_zoom_clamped(new_zoom: Vector2) -> void:
	camera.zoom = new_zoom.clamp(
		Vector2(_MIN_ZOOM, _MIN_ZOOM),
		Vector2(_MAX_ZOOM, _MAX_ZOOM)
	)

# 分发:ScreenTouch 记指位、ScreenDrag 单指平移/双指缩放、MouseButton 桌面滚轮。
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pinch[event.index] = event.position
		else:
			_pinch.erase(event.index)
		# 两指就位:记录起始指距与起始 zoom,供后续 drag 据 ratio 等比缩放。
		if _pinch.size() == 2:
			var positions: Array = _pinch.values()
			_pinch_start_dist = positions[0].distance_to(positions[1])
			_pinch_start_zoom = camera.zoom
	elif event is InputEventScreenDrag:
		_pinch[event.index] = event.position
		if _pinch.size() == 2:
			# 双指缩放:据 cur_dist/start_dist 比值等比乘 start_zoom。
			# Vector2 乘标量为逐分量乘,两分量同比 → 保等比(C3)。
			var positions: Array = _pinch.values()
			var cur_dist: float = positions[0].distance_to(positions[1])
			# start_dist 为 0 时(两指同点落指,合法但无 pinch 意义)跳过防除零 → 此场景 pinch 静默吞
			# (用户须分开两指重落;见 SKILL Gotchas "同点落指吞 pinch"。生产可加最小指距阈值提示)。
			if _pinch_start_dist > 0.0:
				var ratio: float = cur_dist / _pinch_start_dist
				_set_zoom_clamped(_pinch_start_zoom * ratio)
		else:
			# 单指平移:M3 factor 必 Vector2.ONE/zoom。
			_apply_pan(event.relative)
	elif event is InputEventMouseButton:
		# 桌面滚轮:WHEEL_UP 放大(zoom*step,画面元素变大)、WHEEL_DOWN 缩小(zoom/step)。
		# Camera2D.zoom > 1 放大、< 1 缩小,故 UP 乘 step、DOWN 除 step。
		# 仅 pressed(滚轮按下为一次点击事件,pressed==true 触发一次)。
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_zoom_clamped(camera.zoom * _WHEEL_STEP)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_zoom_clamped(camera.zoom / _WHEEL_STEP)
