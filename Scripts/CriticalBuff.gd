extends ModifyAttackBuff
class_name CriticalBuff

func modify_attack(attack_damage: int) -> int:
	return attack_damage * 2
