extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")

func activate(context: Dictionary = {}) -> bool:
	await get_tree().create_timer(0.25).timeout
	var card_effects: Array[CardEffect] = scene.get_last_card_effects()
	buffs_container.release_attack_statuses()  # the replay is a new attack
	buffs_container.set_repeating(true)

	for card_effect: CardEffect in card_effects:
		print("%s applying card_effect %s" % [name, card_effect.get_effect_name()])
		if card_effect.does_require_player_input():
			# Wait for the effect itself: it finishes once the player has chosen, and
			# also when it skips the choice (Gambit with cards in hand, nothing to
			# trash), where waiting for player_input_finished would hang forever.
			await card_effect.apply()
		else:
			card_effect.apply()

	return await super.activate()
	
