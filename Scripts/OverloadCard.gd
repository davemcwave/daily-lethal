extends Card

const TEXT = "Gain [color=#256aff]%d[/color] energy (+1 energy per card played)"

func _ready():
	super._ready()
	
	set_description(TEXT % cards_played.get_cards_played_count())

	
	cards_played.connect("cards_played_modified", self._on_cards_played_cards_played_modified)

func _on_cards_played_cards_played_modified(cards_played_count: int) -> void:
	if not is_inside_tree():
		return
		
	set_description(TEXT % cards_played.get_cards_played_count())
	
	await get_tree().create_timer(0.025).timeout
	await inflate(true)


func play():
	begin_play_resolution()
	handle_sfx()
	
	buffs_container.clear_buffs_added_or_removed_this_turn()

	set_state(State.Playing)
	
	pay_cost(energy_cost)
	
	await apply_card_effects()
	scene.set_last_card_effects(self)
	await get_tree().create_timer(0.1).timeout # So that the panel can be freed from use_energy
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	scene.increment_card_count()
	scene.add_card_played(self)
	
	await discard()
	scene.check_game_over()
	finish_play_resolution()
