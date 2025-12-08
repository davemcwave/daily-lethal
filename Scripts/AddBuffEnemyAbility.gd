extends EnemyAbility
class_name AddBuffEnemyAbility

@export_file("*.scn") var buff_scene
@export var buff: Buff = null

func activate() -> bool:
	var buffs_container: BuffsContainer = get_tree().get_root().get_node('Scene').get_node("BuffsContainer")
	if buff == null:
		buff = load(buff_scene).instantiate()
		
	buffs_container.add_buff(buff)
	return true
