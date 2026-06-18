extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const DECEL := 10.0

# 鼠标相机手感参数（测了直接改这几个常量）
const MOUSE_SENSITIVITY := 0.003
const PITCH_MIN := -1.2  # 俯仰下限（rad，约 -69°）
const PITCH_MAX := 1.2   # 俯仰上限（rad，约 +69°）

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# 相机臂：只旋转它（鼠标 yaw/pitch），角色 mesh 全程不动 —— 不再有反馈循环。
@onready var spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	# ESC 释放鼠标
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	# 释放后点击窗口重新捕获
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	# 鼠标移动 → 相机臂 yaw/pitch（角色不转）
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		spring_arm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, PITCH_MIN, PITCH_MAX)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# 移动方向取自相机臂 basis（只受鼠标影响），绝不取自 Player basis —— 断开反馈循环
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := spring_arm.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := right * input_dir.x - forward * input_dir.y
	direction.y = 0.0
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		var decel := SPEED * DECEL * delta
		velocity.x = move_toward(velocity.x, 0.0, decel)
		velocity.z = move_toward(velocity.z, 0.0, decel)
	move_and_slide()
