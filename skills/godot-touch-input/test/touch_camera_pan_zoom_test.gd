extends SceneTree
## touch_camera_pan_zoom 回归测试(沉淀自 plan Task3,fix review Minor 1)
## 复跑:execute_gdscript code=<本文件内容>,project_path=demo
## FileAccess 读实际脚本(DRY)。覆盖 M3 Vector2 factor / C3 非等比 pan / A5 pinch 等比。
## MouseMotion 桌面 drag 无 headless 测试(Input 单例难注入,见 SKILL Gotchas 真机覆盖)。

func _init():
	var path := "D:/GitHub/godot-ai-kit/skills/godot-touch-input/scripts/touch_camera_pan_zoom.gd"
	var src := FileAccess.get_file_as_string(path)
	assert(src != "" and FileAccess.get_open_error() == 0, "读脚本失败: " + path)
	var s := GDScript.new()
	s.source_code = src
	assert(s.reload() == OK, "touch_camera_pan_zoom 解析失败")
	var cs: Node = s.new()  # 显式 Node(s.new() 返 Variant,GDScript 4.6 warn-as-error)
	var cam := Camera2D.new()
	cs.camera = cam

	# M3: pan 用 Vector2 factor(NEVER 1.0/zoom.x)—— zoom=(2,2) → factor=(0.5,0.5);offset=-(10,0)*(0.5,0.5)=(-5,0)
	cam.zoom = Vector2(2, 2); cam.offset = Vector2.ZERO
	cs._apply_pan(Vector2(10, 0))
	assert(cam.offset == Vector2(-5, 0), "M3 pan Vector2 factor: %s" % str(cam.offset))

	# C3 反向:zoom 非等比时 pan 仍逐分量等比(factor 与 zoom 分量对应)
	cam.zoom = Vector2(2, 4); cam.offset = Vector2.ZERO
	cs._apply_pan(Vector2(10, 10))
	# factor=ONE/(2,4)=(0.5,0.25);offset=-(10,10)*(0.5,0.25)=(-5,-2.5)
	assert(cam.offset == Vector2(-5, -2.5), "C3 非等比 zoom pan 逐分量: %s" % str(cam.offset))

	# A5: pinch 两指 index 0/1 → zoom 各分量同比(比值恒定)
	cam.zoom = Vector2(2, 2); cam.offset = Vector2.ZERO
	var p0 := InputEventScreenTouch.new()
	p0.index = 0; p0.pressed = true; p0.position = Vector2(0, 0)
	cs._input(p0)
	var p1 := InputEventScreenTouch.new()
	p1.index = 1; p1.pressed = true; p1.position = Vector2(100, 0)  # 起始指距 100
	cs._input(p1)
	var d1 := InputEventScreenDrag.new()
	d1.index = 1; d1.position = Vector2(200, 0)  # 当前指距 200 → ratio=2 → zoom=start*2=(4,4)
	cs._input(d1)
	var ratio_xy: float = cam.zoom.x / cam.zoom.y
	assert(abs(ratio_xy - 1.0) < 0.001, "A5 pinch 等比(比值恒定): %s ratio=%f" % [str(cam.zoom), ratio_xy])
	assert(abs(cam.zoom.x - 4.0) < 0.001 and abs(cam.zoom.y - 4.0) < 0.001, "pinch zoom=start*ratio: %s" % str(cam.zoom))

	_mcp_output("cam_pass", true)
	_mcp_done()
