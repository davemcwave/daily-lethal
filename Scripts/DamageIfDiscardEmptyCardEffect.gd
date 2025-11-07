extends DamageCardEffect
class_name DamageIfDiscardEmptyCardEffect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func apply() -> bool:
	var previous_damage_amount = damage_amount
	if discard_panel.is_empty():
		set_damage_amount(damage_amount)
	else:
		set_damage_amount(0)
		var card = discard_panel.get_cards()[0]
	
	var apply_result: bool = await super.apply()
	set_damage_amount(previous_damage_amount)
	return apply_result
