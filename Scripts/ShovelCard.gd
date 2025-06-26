extends Card

#func _ready() -> void:
	#super._ready()
	#discard_panel.connect("updated", self._on_discard_panel_updated)
#
#func _on_discard_panel_updated(card_count: int) -> void:
	#update_description_panel()
	
func update_description_panel() -> void:
	var discard_pile_damage_card_effect: DiscardPileBasedDamageCardEffect = get_card_effects()[0]
	
	card_description = "[center]%s[/center]" % ("Deal damage equal to number of cards in the discard pile")
	$DescriptionPanel/Title.set_text(card_description)

func play():
	scene.increment_card_count()
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
		if card_effect.does_require_player_input():
			await card_effect.player_input_finished
	
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
	discard()
