extends Buff

@onready var scene = get_tree().get_root().get_node("Scene")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var card_effects: Array[CardEffect] = scene.get_last_card_effects()
	
	for card_effect: CardEffect in card_effects:
		card_effect.apply()
	
	super.activate()
	
