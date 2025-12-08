extends Buff
class_name CorrodeBuff

@onready var scene = get_tree().get_root().get_node("Scene")

func activate() -> bool:
	await get_tree().create_timer(0.5).timeout
	var card: Card = scene.get_last_card_played()
	
	if card.is_attack_card():
		if not is_instance_valid(card) or card == null: # or discard_pile.get_card_count() <= 0:
			return super.activate()
			
		card.shrink(0.15)
		await get_tree().create_timer(0.15).timeout
		card.queue_free()
		
	return super.activate()
	
