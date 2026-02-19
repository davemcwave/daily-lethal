extends CardEffect
class_name PickToCreateCardEffect

@export var max_pick_amount: int = 2
@export var card_scenes: Array[Resource] = []
@onready var cards_choose_area: CardsChooseArea = get_tree().get_root().get_node('Scene/CanvasLayer/CardsChooseArea')
@onready var card_creator = cards_choose_area.get_card_creator()

func apply() -> bool:
	cards_choose_area.set_action_name("Add to hand")
	cards_choose_area.set_max_card_choose_amount(max_pick_amount)
	var copy_to_hand_action = load("res://Scenes/CardsChooseAreaCopyToHandAction.scn").instantiate()
	cards_choose_area.set_cards_choose_area_action(copy_to_hand_action)
	
	card_creator.set_card_scenes(card_scenes)
	cards_choose_area.set_source_card(get_parent() if get_parent() is Card else null)
	cards_choose_area.activate(CardsChooseArea.ChooseType.Good, CardsChooseArea.PopulateCardsType.FromCreate)
	
	await cards_choose_area.closed
	
	emit_signal("player_input_finished")
	return super.apply()
