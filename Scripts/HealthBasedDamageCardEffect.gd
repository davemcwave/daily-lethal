extends DamageCardEffect
class_name HealthBasedDamageCardEffect
## Heartbeat: 0 base + your HP + Rage-style bonuses (damage_bonus).

@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func apply() -> bool:
	var hp: int = health.get_health()
	set_damage_amount(hp + damage_bonus)
	return await super.apply()

func get_damage_amount() -> int:
	return health.get_health() + damage_bonus

func get_preview_damage_amount() -> int:
	return health.get_health() + damage_bonus

func get_preview_start_steps() -> Array:
	return _count_steps(health.get_health(), "hp")

func is_count_based() -> bool:
	return true
