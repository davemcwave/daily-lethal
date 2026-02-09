extends CardEffect
class_name HealCardEffect

@export var heal_amount: int = 1
@export_enum("Player", "Enemy") var target_name: String = "Player"
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")
@onready var enemy: Enemy = get_tree().get_root().get_node("Scene/Enemy")

func set_target(new_target: String) -> void:
	target_name = new_target.capitalize()

func set_heal_amount(new_heal_amount: int) -> void:
	heal_amount = new_heal_amount
	
func get_heal_amount() -> int:
	return heal_amount
	
func apply() -> bool:
	var target_node = health if target_name == "Player" else enemy
	target_node.add_health(heal_amount)
	audio_handler.play_sfx("HealSFX")
	return super.apply()
