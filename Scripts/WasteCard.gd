extends Card

func update_description_panel() -> void:
	card_description = "[color=purple]Trash[/color] up to 2 cards from your discard pile."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

#func play():
	#handle_sfx()
	#buffs_container.clear_buffs_added_or_removed_this_turn()
#
	#scene.increment_card_count()
	#set_state(State.Playing)
	#
	#pay_cost(energy_cost)
	#scene.set_last_card_effects(self)
	#discard()
	#
	#await apply_card_effects()
	#
	#await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	#await enemy.activate_on_card_play_debuffs()
	#
