extends CharacterBody3D
## camera_relative_movement.gd — 3D 第三人称玩家控制器(相机相对移动)
## 精简自 demo/scenes/player.gd(经 F14-F16 实测修复 + WASD 人工实测)。
## 保留:相机臂 basis 取向 + 水平面投影 + delta 归一 decel 三件套。
## 省略:鼠标捕获(MOUSE_MODE_CAPTURED)/ESC 的输入 UX(与移动核心无关)。

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const DECEL := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# 相机臂:方向取自它的 basis(只受鼠标影响),绝不取 Player 自身 basis —— 断反馈循环(F15)。
@onready var spring_arm: SpringArm3D = $SpringArm3D


func _physics_process(delta: float) -> void:
	# 重力(3D:JUMP_VELOCITY 正值向上,故重力用减)
	if not is_on_floor():
		velocity.y -= gravity * delta
	# 跳跃(ui_accept = Space,不重定义避免污染 UI 导航)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# WASD 输入(须在 project.godot [input] 段用 physical_keycode 显式定义 —— Godot 4 默认不绑,F14)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# 方向取自相机臂 basis,不是 Player basis(断反馈循环)
	var cam_basis := spring_arm.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := right * input_dir.x - forward * input_dir.y
	# 水平面投影 + 归一(否则相机俯仰时斜向加速)
	direction.y = 0.0
	direction = direction.normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# delta 归一 decel(帧率无关,I2)
		var decel := SPEED * DECEL * delta
		velocity.x = move_toward(velocity.x, 0.0, decel)
		velocity.z = move_toward(velocity.z, 0.0, decel)
	move_and_slide()
