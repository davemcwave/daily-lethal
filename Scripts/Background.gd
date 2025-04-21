extends Node2D

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""

func clear() -> void:
	attempts = 0
	best_card_count = 0

func add_attempt() -> void:
	attempts += 1
	
	#if len(new_attempt) > best_card_count:
		#set_best_card_count(len(new_attempt))
	
func set_best_card_count(new_best_card_count: int) -> void:
	best_card_count = new_best_card_count
	
func set_enemy_name(new_enemy_name: String) -> void:
	enemy_name = new_enemy_name
	
func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios")
	
func is_web() -> bool:
	return OS.has_feature("web")
	
func _ready():
	print(is_mobile())
	print(is_web())
