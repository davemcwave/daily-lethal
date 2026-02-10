extends Card


func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	pay_cost(energy_cost)
	await apply_card_effects()
	print("### applied card effects")
	scene.set_last_card_effects(self)
	var buff: Buff = get_card_effects()[0].get_buff()
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay, {'do_not_activate_buffs': [buff]})
	await discard()
	scene.check_game_over()
	finish_play_resolution()
