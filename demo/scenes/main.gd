extends Node3D

@export var total := 3
var score := 0
var _collected: Dictionary = {}

@onready var score_label: Label = %ScoreLabel

func _ready() -> void:
	add_to_group("main")
	_update_label()
	_connect_crystals.call_deferred()

func _connect_crystals() -> void:
	for crystal in get_tree().get_nodes_in_group("crystals"):
		if not crystal.collected.is_connected(_on_collected):
			crystal.collected.connect(_on_collected)

func _on_collected(sender: Node) -> void:
	if _collected.has(sender):
		return
	_collected[sender] = true
	score += 1
	_update_label()
	if score >= total:
		score_label.text = "Clear!"

func _update_label() -> void:
	score_label.text = "Score: %d/%d" % [score, total]
