extends Card

func update_description_panel() -> void:
	card_description = "[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % ("Deal [color=red]%d[/color] damage 3 times" % get_card_effects()[0].get_damage_amount())
	$DescriptionPanel/Title.set_text(card_description)

func apply_card_effects() -> bool:
	for card_effect in card_effects:
		buffs_container.set_repeating(true)
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
		if card_effect.does_require_player_input():
			await card_effect.player_input_finished
	return true
