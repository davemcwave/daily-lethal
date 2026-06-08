extends Card

func update_description_panel() -> void:
	card_description = "If your hand is empty, deal [color=red]%d[/color] damage." % get_first_damage_card_effect().get_damage_amount()
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
