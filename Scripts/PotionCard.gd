extends Card

func play():
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	set_state(State.Playing)
	await apply_card_effects()
	pay_cost(energy_cost)
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	discard()

func get_card_effects() -> Array:
	return $PlayerChooseEffectCardEffect.get_card_effects_to_choose_from() + [$PlayerChooseEffectCardEffect, ]
	
func update_description_panel() -> void:
	card_description = "[center]%s[/center]" % ("Deal [color=red]%d[/color] damage or Heal [color=#256aff]%d[/color] HP" % [$DamageCardEffect.get_damage_amount(), $HealCardEffect.get_heal_amount()])
	$DescriptionPanel/Title.set_text(card_description)
