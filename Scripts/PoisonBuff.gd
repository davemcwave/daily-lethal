extends ModifyAttackBuff
class_name PoisonBuff

@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")

func modify_attack(damage_amount: int) -> int:
	return 0
	
func activate() -> bool:
	var vulnerable_debuff_scene = load("res://Scenes/VulnerableDebuff.scn")
	var buffs_container_extra_info: Dictionary = buffs_container.get_buff_extra_info()
	var current_damage_amount: int = buffs_container_extra_info['current_damage_amount']
	for i in range(current_damage_amount):
		var vulnerable_debuff = vulnerable_debuff_scene.instantiate()
		target.add_debuff(vulnerable_debuff)
	return super.activate()
