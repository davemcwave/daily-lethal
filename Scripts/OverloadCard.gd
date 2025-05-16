extends Card

const TEXT = "Gain [color=#256aff]%d[/color] energy (+1 energy per card played)"

func _ready():
	super._ready()
	
	set_description(TEXT % cards_played.get_cards_played_count())

	
	cards_played.connect("cards_played_modified", self._on_cards_played_cards_played_modified)

func _on_cards_played_cards_played_modified(cards_played_count: int) -> void:
	set_description(TEXT % cards_played.get_cards_played_count())
	
	await get_tree().create_timer(0.1).timeout
	inflate(true)


func play() -> void:
	
	set_state(State.Playing)
	
	energy.use_energy(energy_cost)
	
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
		if card_effect.does_require_player_input():
			await card_effect.player_input_finished
	
	scene.increment_card_count()
	
	await get_tree().create_timer(0.1).timeout # So that the panel can be freed from use_energy
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
	discard()
