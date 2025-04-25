extends Buff
class_name RetaliateBuff

@onready var scene = get_tree().get_root().get_node("Scene")
@export var target: Node = null

func set_target(new_target: Node) -> void:
	target = new_target
	
func activate() -> void:
	super.activate()
	target.hurt(1)
	
	
