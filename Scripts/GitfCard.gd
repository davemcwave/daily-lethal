extends Card

#func play() -> void:
	#scene.increment_card_count()
	#playing = true
	#
	#energy.use_energy(energy_cost)
	#
	#for card_effect in card_effects:
		#if card_effect_delay > 0.0:
			#await get_tree().create_timer(card_effect_delay).timeout
		#card_effect.apply()
	#
	#buffs_container.activate_on_play_buffs()
	#
	#set_discarded(true)
	#discard_panel.add_card(self)
