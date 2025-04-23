extends CardEffect

@export var draw_amount: int = 1
@onready var deck: Deck = get_tree().get_root().get_node("Scene/Deck")

func set_draw_amount(new_draw_amount: int) -> void:
	draw_amount = new_draw_amount
	
func get_draw_amount() -> int:
	return draw_amount
	
func apply() -> void:
	if deck.can_draw_cards(draw_amount):
		deck.draw_cards(draw_amount)
