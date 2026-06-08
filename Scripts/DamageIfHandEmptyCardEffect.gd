extends DamageCardEffect
class_name DamageIfHandEmptyCardEffect

@onready var hand: Hand = get_tree().get_root().get_node("Scene/HandScrollContainer/Hand")

# The card being played is still parented to the Hand while its effects resolve
# (it is only moved to the discard pile afterwards), so "hand empty" means there
# are no OTHER cards waiting in hand. The played card sits in State.Playing; every
# other card still in hand is State.InHand.
func has_other_cards_in_hand() -> bool:
	for card: Card in hand.get_cards():
		if card.get_state() == Card.State.InHand:
			return true
	return false

func apply() -> bool:
	var previous_damage_amount: int = damage_amount
	if has_other_cards_in_hand():
		set_damage_amount(0)
	var apply_result: bool = await super.apply()
	set_damage_amount(previous_damage_amount)
	return apply_result
