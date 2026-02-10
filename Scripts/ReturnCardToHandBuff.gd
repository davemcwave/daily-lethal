extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

func activate(context: Dictionary = {}) -> bool:
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
	discarded_card.schedule_return_to_hand_after_resolution()
	return super.activate()  # Only consume when we actually schedule a return

	
