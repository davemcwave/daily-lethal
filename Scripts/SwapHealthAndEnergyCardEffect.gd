extends CardEffect

@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func apply() -> bool:
	var current_energy_amount: int = energy.get_energy_amount()
	energy.set_energy(health.get_health())
	health.set_health(current_energy_amount)
	
	return super.apply()
