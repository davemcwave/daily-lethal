extends Card

func update_description_panel() -> void:
	card_description = "Increase all damage cards by +1 damage."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
