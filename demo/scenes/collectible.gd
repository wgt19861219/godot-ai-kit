extends Area3D

signal collected(sender: Node)

func _ready() -> void:
	add_to_group("crystals")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: PhysicsBody3D) -> void:
	if body.is_in_group("player"):
		collected.emit(self)
		queue_free()
