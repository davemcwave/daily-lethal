extends Buff
class_name ModifyAttackBuff

@export var apply_damage: bool = true

func set_apply_damage(new_apply_damage: bool) -> void:
	apply_damage = new_apply_damage
	
func can_apply_damage() -> bool:
	return apply_damage

# TO BE OVERWRITTEN
func modify_attack(attack_damage: int) -> int:
	var modified_attack_damage = attack_damage
	return modified_attack_damage
