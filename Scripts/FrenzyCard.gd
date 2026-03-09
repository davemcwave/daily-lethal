extends Card

func update_description_panel() -> void:
	card_description = "Gain 1 [color=#e67e22]Critical[/color] for each HP less than 3."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
