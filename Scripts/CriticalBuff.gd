extends Buff
class_name CriticalBuff
## "The next time you deal damage, double the damage amount. Will not activate if 0
## damage is dealt." Tier 2 (multiply) of an attack: after Sharp adds, before
## Charge / Flame / Poison convert (so they get the doubled amount).

func activate(context: Dictionary = {}) -> bool:
	var current_damage_amount: int = context['current_damage_amount']
	if current_damage_amount <= 0:
		return true  # a 0-damage attack (a fresh Spark): keep Critical for a real one
	context['current_damage_amount'] = current_damage_amount * 2
	return super.activate()

func preview_attack(context: Dictionary) -> Dictionary:
	if context["current_damage_amount"] <= 0:
		return {}
	context["current_damage_amount"] *= 2
	return {"op": "x", "value": 2, "name": "critical"}
