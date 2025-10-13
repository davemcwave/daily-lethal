extends CardEffect
class_name TrashChooseCardEffect

@export var max_trash_amount: int = 2
@onready var cards_choose_area: CardsChooseArea = get_tree().get_root().get_node('Scene/CanvasLayer/CardsChooseArea')
	
func apply() -> bool:
	cards_choose_area.set_action_name("Trash")
	cards_choose_area.set_choose_up_to_amount(true)
	cards_choose_area.set_max_card_choose_amount(max_trash_amount)
	var trash_action = load("res://Scenes/CardsChooseAreaTrashAction.scn").instantiate()
	cards_choose_area.set_cards_choose_area_action(trash_action)
	cards_choose_area.activate(CardsChooseArea.ChooseType.Bad, CardsChooseArea.PopulateCardsType.FromDiscard)
	if not cards_choose_area.is_closed(): # Just in case it's closed from not having enough cards to start.
		await cards_choose_area.closed
	emit_signal("player_input_finished")
	return super.apply()
