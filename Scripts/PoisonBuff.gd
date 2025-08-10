extends ModifyAttackBuff
class_name PoisonBuff

var original_damage_amount

func modify_attack(attack_damage: int) -> int:
	original_damage_amount = attack_damage
	return 0

func activate() -> void:
	var vulnerable_debuff_scene = load("res://Scenes/VulnerableDebuff.scn")
	for i in range(original_damage_amount):
		var vulnerable_debuff = vulnerable_debuff_scene.instantiate()
		target.add_debuff(vulnerable_debuff)
	super.activate()
