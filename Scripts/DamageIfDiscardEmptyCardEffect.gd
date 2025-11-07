extends DamageCardEffect
class_name DamageIfDiscardEmptyCardEffect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")
@onready var original_damage_amount = damage_amount

func apply() -> bool:
	if discard_panel.is_empty():
		set_damage_amount(damage_amount)
	else:
		set_damage_amount(0)
		var card = discard_panel.get_cards()[0]
		print("CARD! ")
		print(card.get_card_name())
	
	var apply_result: bool = await super.apply()
	damage_amount = original_damage_amount
	return apply_result
