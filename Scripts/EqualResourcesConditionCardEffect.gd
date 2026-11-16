extends DamageCardEffect
class_name EqualResourcesConditionCardEffect
## Balance: when your HP equals your energy, 0 base + that number + Rage-style
## bonuses (damage_bonus); otherwise nothing.

@onready var health: Health = scene.get_node("Health")

func apply() -> bool:
	if health.get_health() != energy.get_energy_amount():
		emit_signal("applied")
		return true
	damage_amount = health.get_health() + damage_bonus
	var result = await super.apply()
	return result

func get_preview_damage_amount() -> int:
	var hp: int = health.get_health()
	return hp + damage_bonus if hp == _preview_energy_after_cost() else 0

func get_preview_start_steps() -> Array:
	var hp: int = health.get_health()
	if hp != _preview_energy_after_cost():
		return [{"op": "start", "value": 0, "name": "base"}]
	return _count_steps(hp, "hp")

func is_count_based() -> bool:
	return true
