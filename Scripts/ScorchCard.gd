extends Card

func update_description_panel() -> void:
	card_description = "Inflict 2 [color=#e67e22]Burn[/color]."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	pay_cost(energy_cost)
	var debuffs_before: Array = enemy.get_debuffs().duplicate()
	await apply_card_effects()
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	var new_debuffs: Array = enemy.get_debuffs().filter(func(d): return not debuffs_before.has(d))
	await enemy.activate_on_card_play_debuffs(new_debuffs)
	await discard()
	scene.check_game_over()
	finish_play_resolution()
