extends DamageCardEffect
class_name EqualResourcesConditionCardEffect

# Deals damage equal to current HP/energy when they are equal; does nothing otherwise.
# Extends DamageCardEffect so IncreaseDamageModifyCardEffect (Rage, etc.) applies normally.

@onready var health: Health = scene.get_node("Health")

func apply() -> bool:
	if health.get_health() != energy.get_energy_amount():
		emit_signal("applied")
		return true

	# damage_amount holds any bonus from increase_damage_amount (Rage etc.)
	var base: int = health.get_health()
	damage_amount = base
	var result = await super.apply()
	return result
