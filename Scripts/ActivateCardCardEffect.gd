extends CardEffect
class_name ActivateCardCardEffect

@export var activation_count: int = 1
@export var ignore_parent_card: bool = false
var card: Card = null

func set_card(new_card) -> void:
	card = new_card
	
func get_card() -> Card:
	return card

func is_card_parent() -> bool:
	if card == null:
		return false
		
	var parent = get_parent()
	if parent is Card and card.get_card_name() == parent.get_card_name():
		return true
	
	return false

func apply() -> bool:
	if card == null:
		return false
		
	if is_card_parent() and ignore_parent_card:
		return false
	
	print("%s applying effects for card %s" % [get_effect_name(), card.get_card_name()])
	for card_effect: CardEffect in card.get_card_effects(true):
		var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		add_child(new_card_effect)
		
		for i in range(activation_count):
			if card_effect.wait_for_effect_applied:
				await new_card_effect.apply()
			else:
				new_card_effect.apply()
			
			if new_card_effect.does_require_player_input():
				await new_card_effect.player_input_finished

	return super.apply()
