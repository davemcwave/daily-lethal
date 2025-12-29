extends Card

func _ready():
	super._ready()
	
	update_description_panel()
	
func update_description_panel() -> void:
	card_description = "[center][shake rate=2.0 level=1 connected=1]Deal [color=red]%d[/color] damage if you have 0 energy, otherwise deal 0[/shake][/center]" % $EnergyConditionDamageCardEffect.get_damage_amount()
	$DescriptionPanel/Title.set_text(card_description)
