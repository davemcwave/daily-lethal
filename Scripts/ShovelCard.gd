extends Card

#func _ready() -> void:
	#super._ready()
	#discard_panel.connect("updated", self._on_discard_panel_updated)
#
#func _on_discard_panel_updated(card_count: int) -> void:
	#update_description_panel()
	
func update_description_panel() -> void:
	var discard_pile_damage_card_effect: DiscardPileBasedDamageCardEffect = get_card_effects()[0]
	
	card_description = "[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % ("Deal damage equal to number of cards in the discard pile")
	$DescriptionPanel/Title.set_text(card_description)

func play():
	begin_play_resolution()
	handle_sfx()
	
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	
	await apply_card_effects()
	
	scene.set_last_card_effects(self)
	
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	
	await discard()
	scene.check_game_over()
	finish_play_resolution()
