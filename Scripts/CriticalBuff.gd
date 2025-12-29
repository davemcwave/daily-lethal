extends Buff
class_name CriticalBuff

func activate(context: Dictionary = {}) -> bool:
	var current_damage_amount: int = context['current_damage_amount']
	context['current_damage_amount'] = current_damage_amount * 2
	return super.activate()
