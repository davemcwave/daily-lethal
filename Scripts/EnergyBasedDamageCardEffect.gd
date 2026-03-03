extends DamageCardEffect
class_name EnergyBasedDamageCardEffect

@export var consume_energy: bool = true

func apply() -> bool:
	var energy_amount: int = energy.get_energy_amount()
	set_damage_amount(energy_amount)
	var applied: bool = await super.apply()
	
	if consume_energy:
		energy.use_energy(energy.get_energy_amount())
	
	return true
