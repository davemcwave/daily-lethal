extends HealCardEffect
class_name HealEnemyCardEffect

#@onready var enemy: Enemy = get_tree().get_root().get_node("Scene/Enemy")
	
func apply() -> bool:
	enemy.add_health(heal_amount)
	audio_handler.play_sfx("HealSFX")
	emit_signal("applied")
	return true
