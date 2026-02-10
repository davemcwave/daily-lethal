extends Card

func _ready():
	super._ready()
	scene.connect("card_count_incremented", self._on_scene_card_count_incremented)

func _on_scene_card_count_incremented() -> void:
	$CardEffect.increase_damage_amount(1)
	
func update_description_panel() -> void:
	card_description = "[center]%s[/center]" % ("Deal [color=red]{damage_amount}[/color] damage (+1 damage per card played)".format({"damage_amount": get_card_effects()[0].get_damage_amount()}))
	$DescriptionPanel/Title.set_text(card_description)

#func discard() -> void:
	#scene.disconnect("card_count_incremented", self._on_scene_card_count_incremented)
	#super.discard()

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	
	await apply_card_effects()
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	
	scene.increment_card_count()
	scene.add_card_played(self)
	await discard()
	scene.check_game_over()
	finish_play_resolution()
