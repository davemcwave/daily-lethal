extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var hand: Hand = scene.get_node("HandScrollContainer/Hand")

func activate(context: Dictionary = {}) -> bool:
	await get_tree().create_timer(0.5).timeout

	if discard_panel.get_card_count() <= 0:
		return true  # Don't consume buff if nothing to return

	var discarded_card: Card = discard_panel.get_last_card()
	var last_played_card = scene.get_last_card_played()

	if discarded_card == null or not is_instance_valid(discarded_card):
		return true  # Don't consume buff

	# Only return the card if it's the one that was played
	if last_played_card == null or discarded_card.get_scene_file_path() != last_played_card.get_scene_file_path():
		return true  # Don't consume buff - this wasn't the played card

	var card_to_return: Card = discarded_card.duplicate(DUPLICATE_USE_INSTANTIATION)
	await get_tree().process_frame
	discarded_card.queue_free()
	discard_panel.update_discard_count()
	card_to_return.set_state(Card.State.InHand)
	card_to_return.normalize_saturation()
	card_to_return.set_rotation(0)
	hand.add_card(card_to_return)
	hand.reorder_cards_by_x_position()
	scene.set_last_card_played(card_to_return)
	return super.activate()  # Only consume when we actually return a card

	
