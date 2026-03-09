extends Card

func update_description_panel() -> void:
	card_description = "Your next card is [color=#2565ff]Free[/color], costing 0 energy to play."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

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
