extends Card

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	pay_cost(energy_cost)
	
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	scene.set_last_card_effects(self)
	
	await discard()
	
	await apply_card_effects()
	scene.check_game_over()
	finish_play_resolution()
	
