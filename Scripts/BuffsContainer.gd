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
	
func has_discount_buff() -> bool:
	
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if is_instance_valid(buff) and buff != null:
			if buff is DiscountBuff:
				return true
			
	return false
	
func get_discount_buff() -> DiscountBuff:
	
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if is_instance_valid(buff) and buff != null:
			if buff is DiscountBuff:
				return buff
			
	return null
	
	
func remove_block_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is BlockBuff:
			buff_panel.queue_free()
			return

func remove_discount_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is DiscountBuff:
			buff_panel.queue_free()
			return

func get_discounted_cost(cost: int) -> int:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is DiscountBuff:
			var discounted_cost: int = max(0, cost-buff.get_discount_amount())
			print("discounted_cost: %d" % discounted_cost)
			return discounted_cost
			
	return cost

	
	
func has_free_buff() -> bool:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
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
	for buff_panel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if buff.is_activated_on_card_play():
			print("activating buff: %s" % buff.get_buff_name())
			buff.activate()
			#await get_tree().create_timer(0.25).timeout
			await buff.activated
			if buff.exceeded_uses() and is_instance_valid(buff_panel) and buff_panel != null and buff_panel.is_inside_tree():
				buff_panel.queue_free()
	animating = false
	
func activate_on_discard_buffs() -> void:
	var buffs_activated = [] # Track if 2 of the same type of buff can be applied on the same turn
	animating = true
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff.is_activated_on_card_discarded() and (buff.can_be_activated_only_once_per_turn() and not buffs_activated.has(buff.get_buff_name())):
			buffs_activated.append(buff.get_buff_name())
			buff.activate()
			#await get_tree().create_timer(0.25).timeout
			await buff.activated
			if buff.exceeded_uses():
				buff_panel.queue_free()
	animating = false
	
