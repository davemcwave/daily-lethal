extends Card

func update_description_panel() -> void:
	card_description = "Your next attack has [color=#2565ff]Charge[/color], gaining energy instead of dealing damage."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

## Plays like any card (pay, effects, statuses react, discard). The Charge it
## gives waits for the next card, like every status gained during a play.
