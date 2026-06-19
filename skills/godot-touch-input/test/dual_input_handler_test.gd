extends SceneTree
## dual_input_handler 回归测试(沉淀自 plan Task2,fix review Minor 1)
## 复跑:execute_gdscript code=<本文件内容>,project_path=demo
## FileAccess 读实际脚本(DRY,脚本更新自动跟);命名 Callable(Godot 4.6 headless lambda 闭包失效,见 Obsidian 教训)

var _touches := []
var _drags := []

func _on_touch(p: Vector2) -> void:
	_touches.append(p)

func _on_drag(p: Vector2, r: Vector2) -> void:
	_drags.append([p, r])

func _init():
	var path := "D:/GitHub/godot-ai-kit/skills/godot-touch-input/scripts/dual_input_handler.gd"
	var src := FileAccess.get_file_as_string(path)
	assert(src != "" and FileAccess.get_open_error() == 0, "读脚本失败: " + path)
	var s := GDScript.new()
	s.source_code = src
	assert(s.reload() == OK, "dual_input_handler 解析失败")
	var h: Node = s.new()  # 显式 Node(s.new() 返 Variant,GDScript 4.6 warn-as-error)
	h.touch_occurred.connect(Callable(self, "_on_touch"))
	h.drag_delta.connect(Callable(self, "_on_drag"))

	# M2: ScreenTouch pressed=true 触发一次
	var t1 := InputEventScreenTouch.new()
	t1.pressed = true; t1.position = Vector2(100, 200)
	h._input(t1)
	assert(_touches.size() == 1 and _touches[0] == Vector2(100, 200), "M2 pressed=true 应触发")

	# M2: pressed=false 不触发(防双触发)
	var t2 := InputEventScreenTouch.new()
	t2.pressed = false; t2.position = Vector2(100, 200)
	h._input(t2)
	assert(_touches.size() == 1, "M2 pressed=false 不应触发(防双触发),实际 %d" % _touches.size())

	# C2: MouseButton LEFT pressed=true 双兼容触发
	var m1 := InputEventMouseButton.new()
	m1.button_index = MOUSE_BUTTON_LEFT; m1.pressed = true; m1.position = Vector2(50, 50)
	h._input(m1)
	assert(_touches.size() == 2, "C2 MouseButton LEFT 双兼容触发,实际 %d" % _touches.size())

	# C2: 非 LEFT 不触发(右键/中键静默忽略,见脚本注释 + SKILL)
	var m2 := InputEventMouseButton.new()
	m2.button_index = MOUSE_BUTTON_RIGHT; m2.pressed = true
	h._input(m2)
	assert(_touches.size() == 2, "非 LEFT 不应触发,实际 %d" % _touches.size())

	# A2: ScreenDrag → drag_delta(position, relative)
	var d1 := InputEventScreenDrag.new()
	d1.position = Vector2(10, 10); d1.relative = Vector2(5, 7)
	h._input(d1)
	assert(_drags.size() == 1 and _drags[0][1] == Vector2(5, 7), "A2 ScreenDrag relative")

	_mcp_output("handler_pass", true)
	_mcp_done()
