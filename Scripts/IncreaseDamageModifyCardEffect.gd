extends ModifyCardEffect
class_name IncreaseDamageModifyCardEffect

@export var damage_increase_amount: int = 1

func set_damage_increase_amount(new_damage_increase_amount: int) -> void:
	damage_increase_amount = new_damage_increase_amount
	
func apply() -> void:
	for card: Card in hand.get_cards():
		for card_effect: CardEffect in card.get_card_effects():
			if card_effect is DamageCardEffect:
				card_effect.increase_damage_amount(damage_increase_amount)
