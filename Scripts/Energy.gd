extends TextureRect

@export var energy_amount: int = 5
const TEXT_TEMPLATE = "[center][b]%d[/b][/center]"

func has_enough_energy(cost: int) -> bool:
	return cost <= energy_amount

func get_energy_amount() -> int:
	return energy_amount
	
func use_energy(cost: int) -> void:
	energy_amount -= cost
	
	$EnergyAmountText.set_text(TEXT_TEMPLATE % energy_amount)
