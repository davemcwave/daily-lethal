extends Buff
class_name RetaliateBuff

@onready var scene = get_tree().get_root().get_node("Scene")
	
func activate() -> void:
	super.activate()
	target.hurt(1)
	
	
