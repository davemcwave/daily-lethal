extends Card

func play() -> void:
	
	scene.increment_card_count()
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	discard()
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
		if card_effect.does_require_player_input():
			await card_effect.player_input_finished
	
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
