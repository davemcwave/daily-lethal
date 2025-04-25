extends Control

@onready var enemy = get_node("Enemy")
@onready var health = get_node("Health")
@onready var background = get_node("/root/Background")
@onready var deck: Deck = get_node("Deck")
@export var starting_card_amount: int = 3
var card_count: int = 0
var last_card_effects: Array[CardEffect] = []

func _ready():
	background.add_attempt()
	
	call_deferred("draw_starting_cards")
	
func set_last_card_effects(card: Card) -> void:
	last_card_effects = []
	for card_effect: CardEffect in card.get_card_effects():
		var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		last_card_effects.append(new_card_effect)
		add_child(new_card_effect)
	
func get_last_card_effects() -> Array[CardEffect]:
	return last_card_effects
	
func draw_starting_cards() -> void:
	var can_draw_cards: bool = deck.can_draw_cards(starting_card_amount)
	if can_draw_cards:
		deck.draw_cards(starting_card_amount)
		
func increment_card_count() -> void:
	card_count += 1

func disable_all_cards() -> void:
	for card: Card in get_tree().get_nodes_in_group("Cards"):
		if not card.is_discarded():
			card.set_discarded(true)
			card.reduce_saturation()
	
func check_game_over() -> void:
	if enemy.is_dead(): # or not hand.has_playable_cards():
		background.set_best_card_count(card_count)
		await get_tree().create_timer(0.75).timeout
		get_tree().change_scene_to_file("res://Scenes/EndGameScreen.scn")
	elif health.is_dead():
		disable_all_cards()
		await get_tree().create_timer(1.0).timeout
		$CanvasLayer/DeadPanel.appear()
