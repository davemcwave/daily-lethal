extends Card

func update_description_panel() -> void:
	card_description = "Your next 2 attacks have [color=#e67e22]Poison[/color], inflicting [color=#e67e22]Vulnerable[/color] instead of dealing damage."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
