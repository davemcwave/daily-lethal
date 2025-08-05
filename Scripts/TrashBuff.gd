extends Buff

@onready var scene = get_tree().get_root().get_node("Scene")
@onready var discard_pile: DiscardPanel = scene.get_node("DiscardPanel")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var card: Card = discard_pile.get_last_card()
	if not is_instance_valid(card) or card == null or discard_pile.get_card_count() <= 0:
		emit_signal("activated")
		return
		
	card.shrink(0.15)
	await get_tree().create_timer(0.15).timeout
	card.queue_free()
	discard_pile.update_discard_count()
	super.activate()
	
