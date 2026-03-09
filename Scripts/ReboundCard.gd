extends Card

func update_description_panel() -> void:
	card_description = "[color=purple]Return[/color] the next card you play to your hand."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
