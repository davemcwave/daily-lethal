extends Card

func update_description_panel() -> void:
	card_description = "[color=purple]Discard[/color] 1 card. Gain 2 energy."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()

	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	scene.set_last_card_effects(self)
	# Exception to the usual order (effects, then discard): Scrap goes to the
	# discard pile first, so the card it discards lands on top of it. Released
	# puzzles depend on that order (Grave Robber, Cerberus: Revive/Seance take
	# the top of the pile).
	await discard()
	await apply_card_effects()
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	await enemy.activate_on_card_play_debuffs()
	scene.check_game_over()
	finish_play_resolution()
