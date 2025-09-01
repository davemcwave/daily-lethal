extends CardEffect
class_name ActivateCardCardEffect

var card: Card = null

func set_card(new_card) -> void:
	card = new_card
	
func get_card() -> Card:
	return card
	
func apply() -> void:
	if card != null:
		card.apply_card_effects()
