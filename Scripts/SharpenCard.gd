extends Card

func update_description_panel() -> void:
	card_description = "Gain 3 [color=#e67e22]Sharp[/color]."
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_description)

	#
#func _ready() -> void:
	#super._ready()
	#$BuffCardEffect.get_buff().set_sharp_count(4)

## Plays like any card (pay, effects, statuses react, discard). The Sharp it
## gives waits for the next card, like every status gained during a play.
