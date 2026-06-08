extends Card

func update_description_panel() -> void:
	card_description = "If your hand is empty, [color=purple]Reclaim[/color] 2 cards from your discard pile."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
