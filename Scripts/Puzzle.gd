extends Node
class_name Puzzle

@export var puzzle_date: String = "2025-01-09"
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

func get_enemy_buffs() -> Array[Buff]:
	return enemy_buffs

func get_enemy_health() -> int:
	return enemy_health

func get_initial_draw_amount() -> int:
	return initial_draw_amount
	
func get_enemy_name() -> String:
	return enemy_name
	
func get_enemy_icon_texture() -> Texture2D:
	return enemy_icon_texture

func get_card_scenes() -> Array[Resource]:
	return card_scenes

func get_puzzle_date() -> String:
	return puzzle_date
	
func get_player_health() -> int:
	return player_health
	
func get_player_energy() -> int:
	return player_energy

func get_enemy_buff_target() -> String:
	return enemy_buff_target
