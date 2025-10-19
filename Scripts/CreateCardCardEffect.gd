extends CardEffect
class_name CreateCardCardEffect

@export var card_to_create_scene: PackedScene
@onready var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')

func apply() -> bool:
	var card: Card = card_to_create_scene.instantiate()
	hand.add_card(card)
	await hand.reorder_cards_by_x_position()
	return super.apply()
