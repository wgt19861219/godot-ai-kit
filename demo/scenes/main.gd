extends Node3D

@export var total := 3
var score := 0
var _collected: Dictionary = {}

@onready var score_label: Label = %ScoreLabel

func _ready() -> void:
	add_to_group("main")
	_update_label()
	_connect_crystals.call_deferred()

# C1:call_deferred 解初始静态 crystal 时序(子 _ready add_to_group 先于帧末 _connect)。
# Minor-2:仅覆盖初始场景 crystal;运行时动态 instance 的 crystal 不会被自动连,
# 需手动调 _connect_crystals(),或让 crystal 主动连 get_first_node_in_group("main")。
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
	# Minor-1:crystal queue_free 后清理悬挂 key,避免 Object 引用泄漏
	sender.tree_exited.connect(func() -> void: _collected.erase(sender))
	if score >= total:
		score_label.text = "Clear!"

func _update_label() -> void:
	score_label.text = "Score: %d/%d" % [score, total]
