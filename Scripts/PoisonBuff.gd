extends Buff
class_name PoisonBuff

func activate(context: Dictionary = {}) -> bool:
	var vulnerable_debuff_scene = load("res://Scenes/VulnerableDebuff.scn")
	var current_damage_amount: int = context['current_damage_amount']
	for i in range(current_damage_amount):
		var vulnerable_debuff = vulnerable_debuff_scene.instantiate()
		target.add_debuff(vulnerable_debuff)
		
	context['deal_damage'] = false
	
	return super.activate()
