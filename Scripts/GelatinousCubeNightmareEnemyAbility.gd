extends EnemyAbility

func activate() -> bool:
	var doom_buff: DoomBuff = load("res://Scenes/DoomBuff.scn").instantiate()
	buffs_container.add_buff(doom_buff)
	return true
