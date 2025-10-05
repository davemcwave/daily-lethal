extends CardEffect
class_name DiscardCardEffect

@export var max_discard_amount: int = 2
@onready var cards_choose_area: CardsChooseArea = get_tree().get_root().get_node('Scene/CanvasLayer/CardsChooseArea')
	
func apply() -> bool:
	cards_choose_area.set_max_card_choose_amount(max_discard_amount)
	cards_choose_area.set_action_name("Discard")
	var discard_action = load("res://Scenes/CardsChooseAreaDiscardAction.scn").instantiate()
	cards_choose_area.set_cards_choose_area_action(discard_action)
	cards_choose_area.activate(CardsChooseArea.ChooseType.Bad, CardsChooseArea.PopulateCardsType.FromHand)
	await cards_choose_area.closed
	emit_signal("player_input_finished")
	return super.apply()
