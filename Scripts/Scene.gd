extends Control

@onready var enemy = get_node("Enemy")
@onready var health = get_node("Health")
@onready var background = get_node("/root/Background")

var card_count: int = 0

func _ready():
	background.add_attempt()
	
func increment_card_count() -> void:
	card_count += 1
	
func check_game_over() -> void:
	if enemy.is_dead(): # or not hand.has_playable_cards():
		background.set_best_card_count(card_count)
		await get_tree().create_timer(0.75).timeout
		get_tree().change_scene_to_file("res://Scenes/EndGameScreen.scn")
	elif health.is_dead():
		await get_tree().create_timer(0.75).timeout
		get_tree().change_scene_to_file("res://Scenes/LoseScreen.scn")
