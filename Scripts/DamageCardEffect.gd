extends CardEffect

@export var damage_amount: int = 1
@export var target: Node = null

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> void:
	target.hurt(damage_amount)
