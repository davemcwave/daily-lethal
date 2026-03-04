extends Card

func update_description_panel() -> void:
	card_description = "[center][shake rate=2.0 level=1 connected=1]If your energy and health are equal, deal damage equal to that number.[/shake][/center]"
	$DescriptionPanel/Title.set_text(card_description)
