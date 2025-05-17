extends Buff

@onready var scene = get_tree().get_root().get_node("Scene")
@onready var hand = scene.get_node("Hand")

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var last_card_scene_file_path: String = scene.get_last_card_scene_file_path()
	var last_card: Card = load(last_card_scene_file_path).instantiate()
	
	last_card.set_state(Card.State.InHand)
	last_card.normalize_saturation()
	last_card.set_rotation(0)
	hand.add_card(last_card)

	super.activate()
	
