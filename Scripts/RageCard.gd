extends Card

func play():
	scene.increment_card_count()
	set_state(State.Playing)
	
	energy.use_energy(energy_cost)
	
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
	set_state(State.Discarded)
	discard_panel.add_card(self)
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
	
