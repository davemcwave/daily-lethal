extends DamageCardEffect
class_name EnergyBasedDamageCardEffect
## Thunderbolt: 0 base + your energy + Rage-style bonuses (damage_bonus).

@export var consume_energy: bool = true

func apply() -> bool:
	var energy_amount: int = energy.get_energy_amount()
	set_damage_amount(energy_amount + damage_bonus)
	var applied: bool = await super.apply()

	if consume_energy:
		energy.use_energy(energy.get_energy_amount())

	return true

func get_preview_damage_amount() -> int:
	return maxi(_preview_energy_after_cost(), 0) + damage_bonus

func get_preview_start_steps() -> Array:
	return _count_steps(maxi(_preview_energy_after_cost(), 0), "energy")

func is_count_based() -> bool:
	return true
