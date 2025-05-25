extends CardEffect

@export var card_amount: int = 1
@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var hand: Hand = scene.get_node("Hand")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

enum ReclaimDirection {
	Top,
	Bottom
}

@export var reclaim_direction: ReclaimDirection = ReclaimDirection.Top

func set_card_amount(new_card_amount: int) -> void:
	card_amount = new_card_amount
	
func get_card_amount() -> int:
	return card_amount
	
func apply() -> void:
	var cards: Array[Card] = discard_panel.get_cards()
	
	if reclaim_direction == ReclaimDirection.Bottom:
		cards.reverse()
	
	for i in range(min(cards.size(), card_amount)):
		var card: Card = cards[i]
		var new_card: Card = card.duplicate(DUPLICATE_USE_INSTANTIATION)
		card.queue_free()
		new_card.set_state(Card.State.InHand)
		new_card.normalize_saturation()
		new_card.set_rotation(0)
		hand.add_card(new_card)
		hand.move_child(new_card, i)
