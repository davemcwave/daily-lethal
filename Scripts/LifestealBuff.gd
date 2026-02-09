extends Buff
class_name LifestealBuff

func activate(context: Dictionary = {}) -> bool:
	var current_damage_amount: int = context['current_damage_amount']
	target.add_health(current_damage_amount)
	return super.activate()
