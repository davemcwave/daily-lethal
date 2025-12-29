extends Card
	#
#func _ready() -> void:
	#super._ready()
	#$BuffCardEffect.get_buff().set_sharp_count(4)

func play():
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	set_state(State.Playing)
	pay_cost(energy_cost)
	print("### applied card effects")
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	await apply_card_effects()
	discard()
	scene.check_game_over()
