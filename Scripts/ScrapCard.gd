extends Card

func play():
	buffs_container.clear_buffs_added_or_removed_this_turn()

	
	scene.increment_card_count()
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	scene.set_last_card_effects(self)
	discard()
	
	await apply_card_effects()
	
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	
