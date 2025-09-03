extends CardEffect

@export var energy_amount: int = 1
@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")

func set_energy_amount(new_energy_amount: int) -> void:
	energy_amount = new_energy_amount
	
func get_energy_amount() -> int:
	return energy_amount
	
func apply() -> bool:
	energy.set_energy(energy_amount)
	
	return super.apply()
