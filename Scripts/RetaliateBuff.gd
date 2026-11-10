extends Buff
class_name RetaliateBuff

@onready var scene = get_tree().get_root().get_node("Scene")
@export var damage_amount: int = 1

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount

## X in the text: the damage it deals back.
func get_description_number() -> int:
	return damage_amount

func activate(context: Dictionary = {}) -> bool:
	await target.hurt(damage_amount)
	return super.activate()
	
	

## Reacts when it (the enemy) is attacked: lights up for attack cards.
func would_act_on_card(card: Card) -> bool:
	return card.is_attack_card()
