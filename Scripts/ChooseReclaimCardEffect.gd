extends CardEffect
class_name ChooseReclaimCardEffect

# Lets the player pick which cards to reclaim from the discard pile back into hand,
# the mirror image of DiscardCardEffect (which picks cards from hand to discard).
# Gambit uses this with require_empty_hand = true and max_reclaim_amount = 2.
@export var max_reclaim_amount: int = 2
# When true the player must reclaim exactly the available amount; the max is clamped
# to the discard size so a small pile can't soft-lock the confirm button.
@export var choose_up_to_amount: bool = false
# Gambit's gate: only offer the reclaim if the hand is otherwise empty. The played
# card is still in hand as State.Playing while effects resolve, so we only count
# OTHER cards (State.InHand). Set false for an ungated choose-reclaim card.
@export var require_empty_hand: bool = true

@onready var cards_choose_area: CardsChooseArea = get_tree().get_root().get_node('Scene/CanvasLayer/CardsChooseArea')
@onready var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node('Scene/DiscardPanel')

func _ready() -> void:
	# Ensure Echo / Repeat wait for the player's selection before continuing.
	requires_player_input = true

func has_other_cards_in_hand() -> bool:
	for card: Card in hand.get_cards():
		if card.get_state() == Card.State.InHand:
			return true
	return false

func apply() -> bool:
	if require_empty_hand and has_other_cards_in_hand():
		emit_signal("applied")
		return true
	if discard_panel.is_empty():
		emit_signal("applied")
		return true

	# Clamp so "reclaim 2" with only 1 card in discard asks for 1 (no soft-lock).
	var effective_max: int = min(max_reclaim_amount, discard_panel.get_card_count())

	cards_choose_area.set_action_name("Reclaim")
	cards_choose_area.set_choose_up_to_amount(choose_up_to_amount)
	cards_choose_area.set_max_card_choose_amount(effective_max)
	var reclaim_action = load("res://Scenes/CardsChooseAreaReclaimAction.scn").instantiate()
	cards_choose_area.set_cards_choose_area_action(reclaim_action)
	cards_choose_area.set_source_card(get_parent() if get_parent() is Card else null)
	cards_choose_area.activate(CardsChooseArea.ChooseType.Good, CardsChooseArea.PopulateCardsType.FromDiscard)
	await cards_choose_area.closed
	emit_signal("player_input_finished")
	return super.apply()
