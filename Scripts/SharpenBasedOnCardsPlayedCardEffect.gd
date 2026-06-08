extends BuffCardEffect
class_name SharpenBasedOnCardsPlayedCardEffect

@onready var cards_played: CardsPlayed = get_tree().get_root().get_node("Scene/CardsPlayed")

# Acuminate: gain Sharp equal to the number of OTHER cards played this turn.
# The Acuminate card itself is already counted by the time effects resolve, so we
# subtract 1. (Drop the `- 1` if you want it to count itself.) The buff template is
# a SharpBuff supplied by the inherited BuffCardEffect.
func apply() -> bool:
	var sharp_amount: int = max(0, cards_played.get_cards_played_count() - 1)

	if sharp_amount <= 0:
		emit_signal("applied")
		return true

	buff.set_sharp_count(sharp_amount)
	# Ensure the Sharp stacks combine into a single panel (and stack with Sharp from
	# Sharpen) instead of spawning a separate panel per cast / Echo repeat. Set on the
	# template before super.apply() duplicates it, so the copy that gets added carries
	# the flag — same mechanism that makes set_sharp_count() stick.
	buff.merge_buff_panels = true
	return await super.apply()
