extends Card

func update_description_panel() -> void:
	card_description = "Reduce your HP to 1. Inflict [color=#e67e22]Vulnerable[/color] equal to the HP you lost."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
