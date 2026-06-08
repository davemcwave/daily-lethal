extends Card

func update_description_panel() -> void:
	card_description = "Trash the top and bottom card of the discard pile, then [color=purple]Reclaim[/color] the rest."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)
