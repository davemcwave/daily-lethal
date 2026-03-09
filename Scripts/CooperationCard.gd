extends Card

func update_description_panel() -> void:
	card_description = "Fully heal the enemy. Gain energy equal to the amount healed."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
