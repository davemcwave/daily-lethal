extends Buff
class_name RetaliateBuff

@onready var scene = get_tree().get_root().get_node("Scene")
@export var damage_amount: int = 1

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount

func activate() -> void:
	super.activate()
	target.hurt(damage_amount)
	
	
