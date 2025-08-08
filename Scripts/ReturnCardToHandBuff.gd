extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var hand: Hand = scene.get_node("Hand")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	
	var card = scene.get_last_card_played()
	
	if card == null or not is_instance_valid(card) or discard_panel.get_card_count() <= 0:
		super.activate()
		return
	else:
		var last_discarded_card: Card = discard_panel.get_last_card().duplicate(DUPLICATE_USE_INSTANTIATION)
		discard_panel.get_last_card().queue_free()
		discard_panel.update_discard_count()
		last_discarded_card.set_state(Card.State.InHand)
		last_discarded_card.normalize_saturation()
		last_discarded_card.set_rotation(0)
		hand.add_card(last_discarded_card)
		hand.reorder_cards_by_x_position()
		scene.set_last_card_played(last_discarded_card)
		super.activate()

	
