extends Card

func play():
	handle_sfx()
	
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	await apply_card_effects()
	pay_cost(energy_cost)
	#scene.set_last_card_effects(self)
	scene.set_last_card_effects_directly(self, [$PlayerChooseEffectCardEffect, ])
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	discard()
	scene.check_game_over()
	
func update_description_panel() -> void:
	card_description = "[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % ("Deal [color=red]%d[/color] damage or Heal [color=#008c10]%d[/color] HP" % [$DamageCardEffect.get_damage_amount(), $HealCardEffect.get_heal_amount()])
	$DescriptionPanel/Title.set_text(card_description)
