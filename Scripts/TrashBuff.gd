extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var discard_pile: DiscardPanel = scene.get_node("DiscardPanel")

func activate(context: Dictionary = {}) -> bool:
	await get_tree().create_timer(0.5).timeout
	var card = scene.get_last_card_played()
	if not is_instance_valid(card) or card == null: # or discard_pile.get_card_count() <= 0:
		return super.activate()

	var source_card: Card = get_source_card()
	var activation_type: int = context.get("activation_type", Buff.ActivationType.OnCardPlay)
	var is_same_card: bool = is_instance_valid(source_card) and source_card == card
	var activated_from_discard: bool = activation_type == Buff.ActivationType.OnCardDiscarded
	if is_same_card and not activated_from_discard:
		return false
		
	card.shrink(0.15)
	await get_tree().create_timer(0.15).timeout
	
	if card != null and is_instance_valid(card):
		card.queue_free()
		
	discard_pile.update_discard_count()
	return super.activate()
	
