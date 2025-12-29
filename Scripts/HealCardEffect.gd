extends CardEffect
class_name HealCardEffect

@export var heal_amount: int = 1
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func set_heal_amount(new_heal_amount: int) -> void:
	heal_amount = new_heal_amount
	
func get_heal_amount() -> int:
	return heal_amount
	
func apply() -> bool:
	health.add_health(heal_amount)
	audio_handler.play_sfx("HealSFX")
	return super.apply()
