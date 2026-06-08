extends CardEffect
class_name TrashDiscardEndsAndReclaimCardEffect

# Trash `trash_from_top` cards from the front and `trash_from_bottom` from the back
# of the discard pile, then reclaim everything left in between into the hand.
# Seance is the 1/1 configuration. Trashing cards each cast keeps recursive reclaim
# loops from going infinite. On small piles the trash ranges can overlap; the index
# set dedupes, so a card is never double-counted.
@export var trash_from_top: int = 1
@export var trash_from_bottom: int = 1

@onready var hand: Hand = scene.get_node("HandScrollContainer/Hand")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

func apply() -> bool:
	var cards: Array[Card] = discard_panel.get_cards()
	var count: int = cards.size()

	var trash_indices := {}
	for i in range(min(trash_from_top, count)):
		trash_indices[i] = true
	for i in range(min(trash_from_bottom, count)):
		trash_indices[count - 1 - i] = true

	var reclaim_index: int = 0
	for i in range(count):
		var card: Card = cards[i]
		discard_panel.remove_card(card)

		if trash_indices.has(i):
			card.queue_free()
			continue

		hand.add_card(card)
		card.set_state(Card.State.InHand)
		card.normalize_saturation()
		card.set_rotation(0)
		card.reset_buffs()
		hand.move_child(card, reclaim_index)
		reclaim_index += 1

	discard_panel.update_discard_count()
	return super.apply()
