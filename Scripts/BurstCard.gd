extends Card

func _ready():
	super._ready()
	
	scene.connect("card_count_incremented", func(): $CardEffect.increase_damage_amount(1))

func update_description_panel() -> void:
	card_description = "[center]%s[/center]" % ("Deal [color=red]{damage_amount}[/color] damage ([color=red]{damage_amount}[/color] cards played) damage".format({"damage_amount": get_card_effects()[0].get_damage_amount()}))
	$DescriptionPanel/Title.set_text(card_description)

func play():
	playing = true
	
	energy.use_energy(energy_cost)
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
	
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
	scene.increment_card_count()
	
	set_discarded(true)
	discard_panel.add_card(self)
