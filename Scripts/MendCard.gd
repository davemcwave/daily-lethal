extends Card

func update_description_panel() -> void:
	card_description = "Gain [color=#008c10]1[/color] HP."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

# Plays like any card, paying its cost after its effects (pay_cost_after_effects).
