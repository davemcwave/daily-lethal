extends Buff

@onready var scene = get_tree().get_root().get_node("Scene")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var hand: Hand = scene.get_node("Hand")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var last_discarded_card: Card = discard_panel.get_last_card().duplicate(DUPLICATE_USE_INSTANTIATION)
	#last_discarded_card.set_global_position(discard_panel.get_last_card().get_global_position())
	discard_panel.get_last_card().queue_free()
	last_discarded_card.set_state(Card.State.InHand)
	last_discarded_card.normalize_saturation()
	last_discarded_card.set_rotation(0)
	hand.add_card(last_discarded_card)
	#hand.move_child(last_discarded_card, hand.get_cards().size())
	super.activate()
	
