extends Node2D

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""
var enemy_texture: Texture2D = null
var puzzle_date: String = ""
var puzzle_scene: String = ""
var next_puzzle_scene: String = ""
var is_current_puzzle: bool = false

func clear() -> void:
	attempts = 0
	best_card_count = 0

func set_is_current_puzzle(new_is_current_puzzle: bool) -> void:
	is_current_puzzle = new_is_current_puzzle
	
func get_is_current_puzzle() -> bool:
	return is_current_puzzle
	
func set_puzzle_scene(new_puzzle_scene: String) -> void:
	puzzle_scene = new_puzzle_scene
	
func set_next_puzzle_scene(new_next_puzzle_scene: String) -> void:
	next_puzzle_scene = new_next_puzzle_scene

func get_next_puzzle_scene() -> String:
	return next_puzzle_scene
	
func get_puzzle_scene() -> String:
	return puzzle_scene

func set_puzzle_date(new_puzzle_date: String) -> void:
	puzzle_date = new_puzzle_date
	
func set_enemy_texture(new_enemy_texture: Texture2D) -> void:
	enemy_texture = new_enemy_texture
	
func get_enemy_texture() -> Texture2D:
	return enemy_texture
	
func add_attempt() -> void:
	attempts += 1
	
	#if len(new_attempt) > best_card_count:
		#set_best_card_count(len(new_attempt))
	
func set_best_card_count(new_best_card_count: int) -> void:
	best_card_count = new_best_card_count
	
func set_enemy_name(new_enemy_name: String) -> void:
	enemy_name = new_enemy_name
