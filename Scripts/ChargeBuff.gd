extends Buff
class_name ChargeBuff

@onready var energy: Energy = get_tree().get_root().get_node('Scene/Energy')

func activate(context: Dictionary = {}) -> bool:
	var current_damage_amount: int = context['current_damage_amount']
	energy.add_energy(current_damage_amount)
	
	context['deal_damage'] = false
	
	return super.activate()

func preview_attack(context: Dictionary) -> Dictionary:
	context["deal_damage"] = false
	return {"op": "to", "text": "%d energy" % context["current_damage_amount"], "name": "charge"}
