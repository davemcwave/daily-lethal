extends CardEffect
class_name LoseEnergyCardEffect

@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")
@export var energy_amount_loss: int = 1

func set_energy_amount_loss(new_energy_amount_loss: int) -> void:
	energy_amount_loss = new_energy_amount_loss
	
func get_energy_amount_loss() -> int:
	return energy_amount_loss
	
func apply() -> bool:
	energy.add_energy(-energy_amount_loss)
	return super.apply()
