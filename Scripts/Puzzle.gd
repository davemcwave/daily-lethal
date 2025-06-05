extends Node
class_name Puzzle

@export_group("Puzzle")
@export var puzzle_date: String = "2025-01-09"
@export_file("*.scn") var next_puzzle_scene
@export var is_current_puzzle: bool = false
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

@export var initial_draw_amount: int = -1

func do_randomize_cards() -> bool:
	return randomize_cards
	
func get_random_card_count() -> int:
	return random_card_count

func get_enemy_buffs() -> Array[Buff]:
	return enemy_buffs

func get_enemy_health() -> int:
	return enemy_health

func get_initial_draw_amount() -> int:
	return initial_draw_amount

func get_is_current_puzzle() -> bool:
	return is_current_puzzle
	
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
	
func get_next_puzzle_scene() -> String:
	return next_puzzle_scene
