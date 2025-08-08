extends ModifyCardEffect
class_name IncreaseDamageModifyCardEffect

@export var damage_increase_amount: int = 1

func set_damage_increase_amount(new_damage_increase_amount: int) -> void:
	damage_increase_amount = new_damage_increase_amount

func get_cards() -> Array:
	return hand.get_cards() + discard_pile.get_cards()
	
func apply() -> void:
	for card: Card in get_cards():
		for card_effect: CardEffect in card.get_card_effects():
			if card_effect is DamageCardEffect and card_effect.can_increase_damage_amount():
				card_effect.increase_damage_amount(damage_increase_amount)
				await get_tree().create_timer(0.05).timeout
