extends Card

func _ready():
	super._ready()
	
	update_description_panel()
	
func update_description_panel() -> void:
	card_description = "[center]Deal [color=red]%d[/color] damage if you have 0 energy, otherwise deal 0[/center]" % $EnergyConditionDamageCardEffect.get_damage_amount()
	$DescriptionPanel/Title.set_text(card_description)
