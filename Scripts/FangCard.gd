extends Card

func update_description_panel() -> void:
	card_description = "[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % ("Deal [color=red]%d[/color] damage, Lose 1 health" % get_card_effects()[0].get_damage_amount())
	$DescriptionPanel/Title.set_text(card_description)
