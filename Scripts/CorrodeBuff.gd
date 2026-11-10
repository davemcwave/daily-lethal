extends Buff
class_name CorrodeBuff
## On the enemy: "Any attack cards used against this enemy are trashed."
## Fires when the enemy is hurt, which happens while the attacking card is still
## being played, so the card is trashed once its play has finished (removing it
## mid-play would cut its remaining effects short).

@onready var scene = get_tree().get_root().get_node("Scene")

func activate(context: Dictionary = {}) -> bool:
	await get_tree().create_timer(0.5).timeout
	# The card hurting the enemy right now. (get_last_card_played() only updates
	# after a card's effects, so it named the card before the attack.)
	var card = scene.get_resolving_card()
	if card == null:
		card = scene.get_last_card_played()
	# (A late hit of a multi-hit attack can arrive after the card was trashed.)
	if is_instance_valid(card) and card.is_attack_card() and not card.has_meta("corroded"):
		card.set_meta("corroded", true)  # a multi-hit attack is trashed once
		await card.trash_when_done()  # at the end of its play (it's mid-attack now)
	return super.activate()

## Trashes the card if it's an attack.
func would_act_on_card(card: Card) -> bool:
	return card.is_attack_card()
