extends Area3D

signal collected

func _ready() -> void:
	add_to_group("crystals")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		collected.emit()
		queue_free()
