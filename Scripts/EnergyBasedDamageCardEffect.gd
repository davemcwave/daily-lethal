extends DamageCardEffect

@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")

func apply() -> void:
	var energy_amount: int = energy.get_energy_amount()
	set_damage_amount(energy_amount)
	energy.use_energy(energy_amount, false)
	target.hurt(damage_amount)
