extends Card

func update_description_panel() -> void:
	card_description = "Gain 2 [color=#2565ff]Blood[/color]. Your next 2 cards cost HP instead of energy."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
