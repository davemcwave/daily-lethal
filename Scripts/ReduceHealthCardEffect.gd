extends CardEffect
class_name ReduceHealthCardEffect

@export var reduce_amount: int = 1
@export var target: Node = null
@export_enum("Player", "Enemy") var target_name: String = "Player"
@onready var health: Health = scene.get_node('Health')
	
func _ready() -> void:
	if target_name == "Enemy":
		target = get_tree().get_root().get_node("Scene/Enemy")
	else:
		target = get_tree().get_root().get_node("Scene/Health")
	
func set_target(new_target) -> void:
	target = new_target
	
	
func apply() -> bool:
	target.set_health(target.get_health() - reduce_amount)
	return super.apply()
