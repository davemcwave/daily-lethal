extends Card

func update_description_panel() -> void:
	card_description = "Gain 1 [color=#c35300]Splinter[/color]: your next attack splits into 1-damage hits, one per point of damage."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

# Mirror SharpenCard: activate OnCardPlay buffs BEFORE applying our own effect so
# the freshly-added Splinter buff isn't consumed by this same play.

## Plays like any card (pay, effects, statuses react, discard).
