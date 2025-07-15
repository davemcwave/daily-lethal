extends Buff
class_name ModifyAttackBuff

# TO BE OVERWRITTEN
func modify_attack(attack_damage: int) -> int:
	var modified_attack_damage = attack_damage
	return modified_attack_damage
