extends DamageCardEffect
class_name DamageIfDiscardEmptyCardEffect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func apply() -> bool:
	if discard_panel.is_empty():
		set_damage_amount(damage_amount)
	else:
		set_damage_amount(0)
	
	return await super.apply()
