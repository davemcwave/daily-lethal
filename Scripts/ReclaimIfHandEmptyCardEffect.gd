extends ReclaimCardEffect
class_name ReclaimIfHandEmptyCardEffect

# Gambit: only reclaim if the hand is empty. Like DamageIfHandEmptyCardEffect, the
# card being played is still in hand (State.Playing) while effects resolve, so we
# only count OTHER cards (State.InHand). `hand` is inherited from ReclaimCardEffect.
func has_other_cards_in_hand() -> bool:
	for card: Card in hand.get_cards():
		if card.get_state() == Card.State.InHand:
			return true
	return false

func apply() -> bool:
	if has_other_cards_in_hand():
		emit_signal("applied")
		return true
	return await super.apply()
