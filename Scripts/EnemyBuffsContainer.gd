extends Control

func add_buff(buff: Buff) -> void:
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
	#buff_panel.set_text(buff.get_buff_name())
	buff_panel.set_buff(buff)
	add_child(buff_panel)

func get_buffs() -> Array[Buff]:
	var buffs: Array[Buff] = []
	for buff_panel: BuffPanel in get_children():
		buffs.append(buff_panel.get_buff())
	return buffs
