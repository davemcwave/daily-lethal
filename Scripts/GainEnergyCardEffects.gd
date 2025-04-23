extends CardEffect
class_name GainEnergyCardEffect

@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")
@export var additional_energy_amount: int = 1

func set_additional_energy_amount(new_additional_energy_amount: int) -> void:
	additional_energy_amount = new_additional_energy_amount
	
func get_additional_energy_amount() -> int:
	return additional_energy_amount
	
func apply() -> void:
	energy.add_energy(additional_energy_amount)
