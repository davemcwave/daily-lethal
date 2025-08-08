extends IncreaseDamageModifyCardEffect
class_name IncreaseDamageSpecificCardModifyCardEffect

@export var target_card_name: String = ""

func get_cards() -> Array:
	var cards: Array = []
	for card: Card in super.get_cards():
		if card.get_card_name() == target_card_name:
			cards.append(card)
	return cards
