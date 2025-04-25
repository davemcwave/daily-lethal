extends GridContainer
class_name BuffsContainer

var animating: bool = false

func is_animating() -> bool:
	return animating
	
func add_buff(new_buff: Buff) -> void:
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
	buff_panel.set_buff(new_buff)
	add_child(buff_panel)

func has_block_buff() -> bool:
	
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if is_instance_valid(buff) and buff != null:
			if buff is BlockBuff:
				return true
			
	return false
	
func remove_block_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is BlockBuff:
			buff_panel.queue_free()
			return
	
func has_free_buff() -> bool:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is FreeBuff:
			return true
			
	return false

func remove_free_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is FreeBuff:
			buff_panel.queue_free()
			return
	
func activate_on_hit_buffs() -> void:
	animating = true
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff.is_activated_on_target_hit():
			await get_tree().create_timer(0.25).timeout
			buff.activate()
	animating = false
	
	
func activate_on_hurt_buffs() -> void:
	animating = true
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if is_instance_valid(buff) and buff != null and buff.is_activated_on_target_hurt():
			await get_tree().create_timer(0.25).timeout
			buff.activate()
	animating = false
	
func activate_on_play_buffs() -> void:
	animating = true
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff.is_activated_on_card_play():
			buff.activate()
			await buff.activated
			if buff.exceeded_uses():
				buff_panel.queue_free()
	animating = false
