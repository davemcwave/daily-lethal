extends DamageCardEffect
class_name HealDamageCardEffect

@onready var health: Health = scene.get_node('Health')

func apply() -> bool:
	var applied: bool = await super.apply()
	var damage_amount: int = get_context()['current_damage_amount']
	health.add_health(damage_amount)
	return applied
