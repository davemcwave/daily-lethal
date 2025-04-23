extends GridContainer
class_name BuffsContainer

func add_buff(new_buff: Buff) -> void:
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
	buff_panel.set_buff(new_buff)
	add_child(buff_panel)

func activate_on_play_buffs() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff.is_activated_on_card_play():
			buff.activate()
			await buff.activated
			if buff.exceeded_uses():
				buff_panel.queue_free()
