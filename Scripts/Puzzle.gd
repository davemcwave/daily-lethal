extends Node
class_name Puzzle

@export_group("Puzzle")
@export var puzzle_date: String = "2025-01-09"
@export_file("*.scn") var previous_puzzle_scene
@export_file("*.scn") var next_puzzle_scene
@export var randomize_cards: bool = false
@export var random_card_count: int = 6

@export_group("Enemy")
@export var enemy_health: int = 10
@export var enemy_name: String = "Bad Guy"
@export var enemy_icon_texture: Texture2D = null
@export_enum("Player", "Enemy") var enemy_buff_target: String = "Player"

@export var enemy_buffs: Array[Buff]

@export_group("Player")
@export var player_health: int = 3
@export var player_energy: int = 5

@export_group("Cards")
@export var card_scenes: Array[Resource]
@export var card_solution: Array[Resource]

@export var initial_draw_amount: int = -1

@export_group("Dialog")
@export_enum("Player", "Enemy") var dialogue_first: String = "Player"
@export_multiline var dialogue_lines: Array[String]
@export_multiline var enemy_hurt_lines: Array[String]
@export var enemy_hurt_line_chance: float = 0.0

var test_puzzle: bool = false

func get_hurt_line_chance() -> float:
	return enemy_hurt_line_chance
	
func set_test_puzzle(new_test_puzzle: bool) -> void:
	test_puzzle = new_test_puzzle 

func get_enemy_hurt_lines() -> Array[String]:
	return enemy_hurt_lines
	
func get_dialogue_first() -> String:
	return dialogue_first

func has_any_cards(check_card_scenes: Array) -> bool:
	var cards: Array[Card] = []
	for card_scene in card_scenes:
		cards.append(card_scene.instantiate())
		
	for check_card_scene in check_card_scenes:
		var check_card: Card = check_card_scene.instantiate()
		
		for card: Card in cards:
			if card.get_card_name() == check_card.get_card_name():
				return true
	return false
	
	
func get_dialogue_lines() -> Array[String]:
	return dialogue_lines
	
func is_test_puzzle() -> bool:
	return test_puzzle
	
func do_randomize_cards() -> bool:
	return randomize_cards
	
func get_card_solution() -> Array:
	return card_solution
	
func get_random_card_count() -> int:
	return random_card_count

func get_enemy_buffs() -> Array[Buff]:
	return enemy_buffs

func get_enemy_health() -> int:
	return enemy_health
	
func get_previous_puzzle_scene():
	return previous_puzzle_scene

func get_initial_draw_amount() -> int:
	return initial_draw_amount
	
func set_initial_draw_amount(new_initial_draw_amount: int) -> void:
	initial_draw_amount = new_initial_draw_amount
	
func get_enemy_name() -> String:
	return enemy_name
	
func get_enemy_icon_texture() -> Texture2D:
	return enemy_icon_texture

func get_card_scenes() -> Array[Resource]:
	return card_scenes
	
func clear_card_scenes() -> void:
	card_scenes.clear()

func set_card_scenes(new_card_scenes: Array[Resource]) -> void:
	card_scenes = new_card_scenes
	
func add_card_scene(new_card_scene: Resource) -> void:
	card_scenes.append(new_card_scene)

func get_puzzle_date() -> String:
	return puzzle_date
	
func get_player_health() -> int:
	return player_health
	
func get_player_energy() -> int:
	return player_energy

func get_enemy_buff_target() -> String:
	return enemy_buff_target
	
func get_next_puzzle_scene():
	return next_puzzle_scene
