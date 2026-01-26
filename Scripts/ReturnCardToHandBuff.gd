extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var hand: Hand = scene.get_node("HandScrollContainer/Hand")

func activate(context: Dictionary = {}) -> bool:
	await get_tree().create_timer(0.5).timeout
	print("=== ReturnCardToHandBuff activate ===")

	if discard_panel.get_card_count() <= 0:
		print("EARLY RETURN: discard empty")
		return true  # Don't consume buff if nothing to return

	var discarded_card: Card = discard_panel.get_last_card()
	var last_played_card = scene.get_last_card_played()

	if discarded_card == null or not is_instance_valid(discarded_card):
		print("EARLY RETURN: discarded null/invalid")
		return true  # Don't consume buff

	print("discarded: %s, last_played: %s, same: %s" % [discarded_card, last_played_card, discarded_card == last_played_card])
	# Only care about cards that were actually played (not discarded by effects)
	if last_played_card == null or discarded_card != last_played_card:
		print("EARLY RETURN: not the played card")
		return true  # Don't consume buff - this wasn't the played card

	print("RETURNING card to hand!")

	# Return this card to hand
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

	
