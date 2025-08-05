extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_pile: DiscardPanel = scene.get_node("DiscardPanel")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var card: Card = scene.get_last_card_played()
	if not is_instance_valid(card) or card == null: # or discard_pile.get_card_count() <= 0:
		super.activate()
		return
		
	card.shrink(0.15)
	await get_tree().create_timer(0.15).timeout
	card.queue_free()
	#discard_pile.update_discard_count()
	super.activate()
	
