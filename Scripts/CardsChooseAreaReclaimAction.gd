extends CardsChooseAreaAction
class_name CardsChooseAreaReclaimAction

# Moves a chosen card from the discard pile back into the hand. The card handed in
# is the real discard-pile card (CardsChooseArea resolves it by id), so we mirror
# ReclaimCardEffect's per-card steps: pull it out of the discard, add it to the
# hand, and reset its discarded visual/buff state. (CardsChooseAreaCopyToHandAction
# only adds to hand — it's for freshly created cards that have no parent — so it
# can't be reused here.)
@onready var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node('Scene/DiscardPanel')

func apply(card: Card) -> bool:
	discard_panel.remove_card(card)
	hand.add_card(card)
	card.set_state(Card.State.InHand)
	card.normalize_saturation()
	card.set_rotation(0)
	card.reset_buffs()
	return super.apply(card)
