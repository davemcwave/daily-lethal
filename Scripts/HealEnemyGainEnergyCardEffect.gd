extends HealEnemyCardEffect
class_name HealEnemyGainEnergyCardEffect

@onready var energy: Energy = get_tree().get_root().get_node('Scene/Energy')

func apply() -> bool:
	heal_amount = enemy.get_max_health() - enemy.get_health()
	enemy.add_health(heal_amount)
	energy.add_energy(heal_amount)
	audio_handler.play_sfx("HealSFX")
	return super.apply()
