extends Card

func update_description_panel() -> void:
	card_description = "Gain [color=#e67e22]Sharp[/color] equal to the number of cards played."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

# Mirror SharpenCard: resolve OnCardPlay buffs before adding the Sharp so the new
# stack isn't immediately reduced by this same play.

## Plays like any card (pay, effects, statuses react, discard).
