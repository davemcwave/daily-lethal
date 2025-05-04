extends Card

func update_description_panel() -> void:
	card_description = "[center]%s[/center]" % ("Attack 3 times, each attack does %d damage" % get_card_effects()[0].get_damage_amount())
	$DescriptionPanel/Title.set_text(card_description)
