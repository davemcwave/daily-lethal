extends DamageCardEffect
class_name EnergyBasedDamageCardEffect

func apply() -> bool:
	var energy_amount: int = energy.get_energy_amount()
	set_damage_amount(energy_amount)
	energy.use_energy(energy_amount)
	return await super.apply()
