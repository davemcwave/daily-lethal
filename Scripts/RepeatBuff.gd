extends Buff

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")

func activate() -> bool:
	await get_tree().create_timer(0.25).timeout
	var card_effects: Array[CardEffect] = scene.get_last_card_effects()
	
	buffs_container.set_repeating(true)

	for card_effect: CardEffect in card_effects:
		print("%s applying card_effect %s" % [name, card_effect.get_effect_name()])
		card_effect.apply()
		if card_effect.does_require_player_input():
			print("%s does_require_player_input" % card_effect.name)
			await card_effect.player_input_finished
			print("%s found player input" % card_effect.name)

	return await super.activate()
	
