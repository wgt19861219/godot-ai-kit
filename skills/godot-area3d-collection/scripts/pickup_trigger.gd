extends Area3D
## pickup_trigger.gd — Area3D 收集交互(组优先 + signal 带 sender)
## 精简自 demo/scenes/collectible.gd(经 I3/C2 修复 + 人工实测)。

# 带 sender 参数:主控可据此去重(C2),避免同一收集物重复计分。
signal collected(sender: Node)


func _ready() -> void:
	add_to_group("crystals")
	# connect 而非硬连外部方法:节点生命周期安全,运行时动态实例可重连。
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: PhysicsBody3D) -> void:
	# 组优先(I3):不硬判 is CharacterBody3D(过窄,NPC/载具拿不到)。
	if body.is_in_group("player"):
		collected.emit(self)
		queue_free()
