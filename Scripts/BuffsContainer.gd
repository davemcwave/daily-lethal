extends GridContainer
class_name BuffsContainer

var animating: bool = false
var buffs_added_this_turn: Array = []
var buffs_removed_this_turn: Array = []
var buff_context: Dictionary = {}
var repeating: bool = false
var highlighted_buff_panels: Array = []

@onready var scene: Scene = get_parent()

func _ready() -> void:
	call_deferred('activate_add_buff_enemy_abilities')

func activate_add_buff_enemy_abilities() -> void:
	for enemy_ability: EnemyAbility in scene.get_enemy_abilities():
		if enemy_ability is AddBuffEnemyAbility:
			await enemy_ability.activate()
			
func set_repeating(new_repeating: bool) -> void:
	repeating = new_repeating
	
func is_repeating() -> bool:
	return repeating

func is_animating() -> bool:
	return animating
	
func add_buff(new_buff: Buff) -> void:
	if _try_merge_existing_buff(new_buff):
		return
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
	buff_panel.set_buff(new_buff)
	
	print("%s buff being added" % new_buff.get_buff_name())
	add_child(buff_panel)
	var buff_instance_id = new_buff.get_instance_id()
	buffs_added_this_turn.append(buff_instance_id)
	scene.emit_buff_added_signal(new_buff)

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

func has_charge_buff() -> bool:
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is ChargeBuff:
			return true
			
	return false
	
func remove_charge_buff() -> void:
	for buff_panel: BuffPanel in get_children():
		var buff: Buff = buff_panel.get_buff()
		if buff is ChargeBuff:
			add_buff_removed_this_turn(buff.get_buff_name())
			buff_panel.queue_free()
			return
	
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
			
func get_modify_attack_buffs() -> Array:
	var modify_attack_buffs = []
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel):
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if buff is ModifyAttackBuff:
			modify_attack_buffs.append(buff)
	
	return modify_attack_buffs
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
	
func remove_all_buffs() -> bool:
	for buff_panel: BuffPanel in get_children():
		buff_panel.queue_free()
		await buff_panel.tree_exited
	return true
	

func get_buffs(buff_activation_type: Buff.ActivationType) -> Array:
	var buffs: Array = []
	for buff_panel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if buff.matches_activation_type(buff_activation_type):
			buffs.append(buff)
			
	return buffs

func set_buff_context(new_buff_context: Dictionary) -> void:
	buff_context = new_buff_context

func merge_buff_context(new_buff_context: Dictionary) -> void:
	buff_context.merge(new_buff_context, true)

func get_buff_context() -> Dictionary:
	return buff_context

#func get_buff_panels_by_activation_order(buff_panels: Array, buff_activation_type: Buff.ActivationType) -> Array:
	#var reordered_buff_panels = buff_panels.duplicate()
#
	#if buff_activation_type == Buff.ActivationType.OnAttack:
		#reordered_buff_panels.sort_custom(self._compare_attack_buffs)
#
	#return reordered_buff_panels
#
#
#func _compare_attack_buffs(a: BuffPanel, b: BuffPanel) -> bool:
	#var buff_a: Buff = a.get_buff()
	#var buff_b: Buff = b.get_buff()
#
	## Define priority (lower index => earlier activation)
	#var priority_a = _attack_priority(buff_a)
	#var priority_b = _attack_priority(buff_b)
#
	#if priority_a == priority_b:
		## Stable fallback — alphabetical or creation order
		#return buff_a.get_buff_name() < buff_b.get_buff_name()
#
	#return priority_a < priority_b
#
#
#func _attack_priority(buff: Buff) -> int:
	## Adjust this to match your desired OnAttack order:
	#match buff.get_buff_name():
		#"Critical":
			#return 0
		#"Poison":
			#return 1
		#Buff.BuffType.Echo:
			#return 2
		#_:
			#return 99

	
func activate_buffs(buff_activation_type: Buff.ActivationType, context: Dictionary = {}) -> Array:
	context['activation_type'] = buff_activation_type
	
	var activation_id: int = ResourceUID.create_id()
	context['activation_id'] = activation_id
	
	print("activate buffs | %s" % str(Buff.ActivationType.keys()[buff_activation_type]))
	# Track if 2 of the same type of buff can be applied on the same turn
	# Also keep track of those buffs that were removed during this turn but 
	# outside of the of this function.
	var blocked_buff_names: Array = buffs_removed_this_turn.duplicate()
	var buff_instance_ids_activated: Array = []
	var buff_objects_activated = []
	print("------ animating is true")
	animating = true
	
	var activation_queue = _build_buff_activation_queue(buff_activation_type, context, blocked_buff_names, buff_instance_ids_activated, buffs_added_this_turn)
	for activation_candidate in activation_queue:
		var buff_panel: BuffPanel = activation_candidate['panel']
		var buff: Buff = activation_candidate['buff']
		
		set_repeating(false)
		buff_objects_activated.append(buff.duplicate())
		
		print("activating buff: %s" % buff.get_buff_name())
		await buff.activate(context)
			
		print("%s activated!" % buff.get_buff_name())
		if buff.exceeded_uses() and is_instance_valid(buff_panel) and buff_panel != null and buff_panel.is_inside_tree() and not buff.is_freed_manually():
			buff_panel.queue_free()
	animating = false
	print("animating is false ------")
	return buff_objects_activated
	
func _build_buff_activation_queue(buff_activation_type: Buff.ActivationType, context: Dictionary, blocked_buff_names: Array, buff_instance_ids_activated: Array, buffs_added_instance_ids: Array) -> Array:
	var activation_queue: Array = []
	var current_repeating_state: bool = is_repeating()
	var buff_panels = get_children()
	buff_panels.sort_custom(func(a, b): return a.get_buff().priority < b.get_buff().priority)
	for buff_panel in buff_panels:
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if not _should_consider_buff(buff, buff_activation_type, context):
			continue
		
		var buff_instance_id = buff.get_instance_id()
		var buff_is_repeating: bool = current_repeating_state and buff.can_single_turn_repeat()
		if !buff_is_repeating and buff.can_be_activated_only_once_per_turn():
			if blocked_buff_names.has(buff.get_buff_name()):
				continue
			if buff_instance_ids_activated.has(buff_instance_id) or buffs_added_instance_ids.has(buff_instance_id):
				continue
		
		activation_queue.append({
			'buff': buff,
			'panel': buff_panel
		})
		blocked_buff_names.append(buff.get_buff_name())
		buff_instance_ids_activated.append(buff_instance_id)
		if buff_is_repeating:
			current_repeating_state = false
	return activation_queue

func _should_consider_buff(buff: Buff, buff_activation_type: Buff.ActivationType, context: Dictionary) -> bool:
	if not buff.matches_activation_type(buff_activation_type):
		return false
	
	var do_not_activate_buffs: Array = context.get('do_not_activate_buffs', [])
	if do_not_activate_buffs.size() > 0:
		for do_not_activate_buff in do_not_activate_buffs:
			if (not is_instance_valid(buff)) or (not is_instance_valid(do_not_activate_buff)) or (buff == do_not_activate_buff):
				return false
	return true

func _try_merge_existing_buff(new_buff: Buff) -> bool:
	if not is_instance_valid(new_buff) or not new_buff.merge_buff_panels:
		return false
	
	for buff_panel: BuffPanel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel.is_queued_for_deletion():
			continue
			
		var existing_buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(existing_buff) or not existing_buff.merge_buff_panels:
			continue
		
		if existing_buff.can_merge_with(new_buff):
			existing_buff.merge_with(new_buff)
			return true
	return false
