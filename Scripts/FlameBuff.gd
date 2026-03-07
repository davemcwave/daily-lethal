extends Buff
class_name FlameBuff

@onready var enemy: Enemy = get_tree().get_root().get_node("Scene/Enemy")

func activate(context: Dictionary = {}) -> bool:
	var burn_amount: int = context.get("current_damage_amount", 1)
	var burn_debuff: BurnDebuff = load("res://Scenes/BurnDebuff.scn").instantiate()
	burn_debuff.burn_count = burn_amount
	var has_existing_burn: bool = enemy.get_debuffs().any(func(d): return d is BurnDebuff)
	if not has_existing_burn:
		burn_debuff.skip_next_activation = true
	enemy.add_debuff(burn_debuff)
	context["deal_damage"] = false
	return super.activate()
