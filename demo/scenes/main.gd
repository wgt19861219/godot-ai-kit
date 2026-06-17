extends Node3D

@export var total := 3
var score := 0

@onready var score_label: Label = %ScoreLabel

func _ready() -> void:
	_update_label()
	for crystal in get_tree().get_nodes_in_group("crystals"):
		crystal.collected.connect(_on_collected)

func _on_collected() -> void:
	score += 1
	_update_label()
	if score >= total:
		score_label.text = "过关!"

func _update_label() -> void:
	score_label.text = "收集: %d/%d" % [score, total]
