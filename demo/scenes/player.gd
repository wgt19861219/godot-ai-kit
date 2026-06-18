extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const DECEL := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		var target_y := atan2(-direction.x, -direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_y, 10.0 * delta)
		spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, target_y, 10.0 * delta)
	else:
		var decel := SPEED * DECEL * delta
		velocity.x = move_toward(velocity.x, 0.0, decel)
		velocity.z = move_toward(velocity.z, 0.0, decel)
	move_and_slide()
