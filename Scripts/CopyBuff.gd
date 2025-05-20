extends Buff

const USE_ENERGY_COST_FROM_ORIGINAL_CARD: int = -1
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var hand = scene.get_node("Hand")
@export var energy_cost_copy: int = USE_ENERGY_COST_FROM_ORIGINAL_CARD

func activate() -> void:
	await get_tree().create_timer(0.5).timeout
	var last_card: Card = scene.get_last_card_backup()
	last_card.set_state(Card.State.InHand)
	last_card.normalize_saturation()
	last_card.set_rotation(0)
	
	if energy_cost_copy != USE_ENERGY_COST_FROM_ORIGINAL_CARD:
		last_card.set_energy_cost(energy_cost_copy)
	
	hand.add_card(last_card)

	super.activate()
	
