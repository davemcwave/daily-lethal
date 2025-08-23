extends Card

func play():
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	set_state(State.Playing)
	pay_cost(energy_cost)
	await apply_card_effects()
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	discard()
