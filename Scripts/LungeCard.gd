extends Card

func update_description_panel() -> void:
	card_description = "[center]%s[/center]" % ("Deal [color=red]%d[/color] damage, Gain +1 energy" % get_card_effects()[0].get_damage_amount())
	$DescriptionPanel/Title.set_text(card_description)
