extends GridContainer
class_name BuffsContainer

var animating: bool = false
var buffs_added_this_turn: Array = []
var buffs_removed_this_turn: Array = []

func is_animating() -> bool:
	return animating
	
func add_buff(new_buff: Buff) -> void:
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
	buff_panel.set_buff(new_buff)
	add_child(buff_panel)
	var buff_instance_id = new_buff.get_instance_id()
	buffs_added_this_turn.append(buff_instance_id)

func clear_buffs_added_or_removed_this_turn() -> void:
	clear_buffs_added_this_turn()
	clear_buffs_removed_this_turn()

func clear_buffs_added_this_turn() -> void:
	buffs_added_this_turn.clear()
	
func add_buff_removed_this_turn(new_buff: String) -> void:
	buffs_removed_this_turn.append(new_buff)
	
func clear_buffs_removed_this_turn() -> void:
	buffs_removed_this_turn.clear()

func has_buff_been_removed_this_turn(buff_name: String) -> bool:
	return buffs_removed_this_turn.has(buff_name)

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
			add_buff_removed_this_turn(buff.get_buff_name())
			buff_panel.queue_free()
			return

func remove_discount_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is DiscountBuff:
			add_buff_removed_this_turn(buff.get_buff_name())
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
	
func has_blood_buff() -> bool:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is BloodBuff:
			return true
			
	return false
	

func remove_free_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is FreeBuff:
			add_buff_removed_this_turn(buff.get_buff_name())
			buff_panel.queue_free()
			return
			
func remove_blood_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is BloodBuff:
			add_buff_removed_this_turn(buff.get_buff_name())
			buff_panel.queue_free()
			return
			
func has_modify_attack_buff() -> bool:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is ModifyAttackBuff:
			return true
			
	return false

func activate_buff(target_buff: Buff) -> void:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff == target_buff:
			buff.activate()
			buff_panel.queue_free()
			return
	
func get_modify_attack_buff():
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is ModifyAttackBuff:
			return buff
			
	return null
	
	
func remove_buff_by_name(buff_name: String) -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff.get_buff_name() == buff_name:
			buff_panel.queue_free()
			return
	
	
	

func get_buffs(buff_activation_type: Buff.ActivationType) -> Array:
	var buffs: Array = []
	for buff_panel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if buff.get_activation_type() == buff_activation_type:
			buffs.append(buff)
			
	return buffs
	

func activate_buffs(buff_activation_type: Buff.ActivationType) -> Array:
	print("activate buffs | %s" % str(buff_activation_type))
	# Track if 2 of the same type of buff can be applied on the same turn
	# Also keep track of those buffs that were removed during this turn but 
	# outside of the of this function.
	var buffs_activated = buffs_removed_this_turn
	
	print("------ animating is true")
	animating = true
	for buff_panel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if buff.get_activation_type() == buff_activation_type:
				
			var buff_instance_id = buff.get_instance_id()
			
			if buff.can_be_activated_only_once_per_turn() and (buffs_activated.has(buff.get_buff_name()) or buffs_added_this_turn.has(buff_instance_id)):
				continue
				
			buffs_activated.append(buff.get_buff_name())
			print("activating buff: %s" % buff.get_buff_name())
			buff.activate()
			#await get_tree().create_timer(0.25).timeout
			if buff.wait_for_activated_signal:
				await buff.activated
				
			print("%s activated!" % buff.get_buff_name())
			if buff.exceeded_uses() and is_instance_valid(buff_panel) and buff_panel != null and buff_panel.is_inside_tree() and not buff.is_freed_manually():
				buff_panel.queue_free()
	animating = false
	print("animating is false ------")
	return buffs_activated
	
