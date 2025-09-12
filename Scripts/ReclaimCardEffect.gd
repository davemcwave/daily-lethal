extends CardEffect

@export var card_amount: int = 1
#@onready var scene: Scene = get_tree().get_root().get_node("Scene")
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
	
func apply() -> bool:
	var cards: Array[Card] = discard_panel.get_cards()
	
	if reclaim_direction == ReclaimDirection.Bottom:
		cards.reverse()
	
	for i in range(min(cards.size(), card_amount)):
		var card: Card = cards[i]
		card.get_parent().remove_child(card)
		hand.add_card(card)
		
		card.set_state(Card.State.InHand)
		card.normalize_saturation()
		card.set_rotation(0)
		card.reset_buffs()
		
		hand.move_child(card, i)
		#await get_tree().create_timer(0.1).timeout
	print("discard_panel size: %d" % discard_panel.get_cards().size())
	
	discard_panel.update_discard_count()
	
	return super.apply()
