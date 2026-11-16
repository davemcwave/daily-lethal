extends CardEffect
class_name ReturnToHandCardEffect
## Returns the card this effect is on to your hand after it finishes playing
## (it still goes through the discard first, so discard-pile effects see it).
## Same mechanism as the Return buff (Rebound), but for the card itself.

func apply() -> bool:
	var card := get_parent() as Card
	if card != null:
		card.schedule_return_to_hand_after_resolution()
	return super.apply()
