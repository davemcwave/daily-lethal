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
	child_entered_tree.connect(func(_c): queue_regroup())
	child_exiting_tree.connect(func(_c): queue_regroup())

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
	var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.tscn").instantiate()
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
	# A copy: panels can leave while we wait (a buff used up meanwhile).
	for buff_panel in get_children().duplicate():
		if not is_instance_valid(buff_panel) or buff_panel.is_queued_for_deletion():
			continue
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
		var charged: bool = activation_candidate.get('charged', false)

		set_repeating(false)
		buff_objects_activated.append(buff.duplicate())

		print("activating buff: %s" % buff.get_buff_name())
		# A later hit of the attack card that already used this status: it acts
		# again without using another use (Slay the Spire: "your next attack" means
		# the whole card).
		if not is_instance_valid(buff):
			continue  # removed meanwhile (a used-up attack status)
		var uses_before: int = buff.uses_amount
		if charged:
			buff.uses_amount += 1
		await buff.activate(context)
		if charged and is_instance_valid(buff):
			buff.uses_amount = uses_before
			if is_instance_valid(buff_panel):
				buff_panel.update_text()

		print("%s activated!" % buff.get_buff_name())
		if not is_instance_valid(buff) or buff.has_meta(ATTACK_PLAY_META):
			continue  # an attack status: removed when its card's effects are done
		if buff.exceeded_uses() and is_instance_valid(buff_panel) and buff_panel != null and buff_panel.is_inside_tree() and not buff.is_freed_manually():
			buff_panel.queue_free()
	animating = false
	print("animating is false ------")
	return buff_objects_activated
	
func _build_buff_activation_queue(buff_activation_type: Buff.ActivationType, context: Dictionary, blocked_buff_names: Array, buff_instance_ids_activated: Array, buffs_added_instance_ids: Array) -> Array:
	var activation_queue: Array = []
	var current_repeating_state: bool = is_repeating()
	# Attack statuses (OnAttack) and the ones that react to the attack (React:
	# Lifesteal) count attack cards: once per card, every hit of it.
	var per_card := buff_activation_type == Buff.ActivationType.OnAttack or buff_activation_type == Buff.ActivationType.React
	var play_key := _attack_play_key() if per_card else ""
	var buff_panels = get_children()
	# Tier first (priority: on an attack, Sharp 0 add -> Critical 1 multiply ->
	# Charge/Flame/Poison 2 convert -> Splinter 3 split), then the order the buffs
	# were gained. sort_custom isn't stable, so the gained order is the tie-break.
	buff_panels.sort_custom(func(a, b):
		var pa: int = a.get_buff().priority
		var pb: int = b.get_buff().priority
		return pa < pb if pa != pb else a.get_index() < b.get_index())
	for buff_panel in buff_panels:
		if not is_instance_valid(buff_panel) or buff_panel == null and not buff_panel.is_inside_tree():
			continue
			
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff):
			continue
		
		if not _should_consider_buff(buff, buff_activation_type, context):
			continue
		
		var buff_instance_id = buff.get_instance_id()
		# Attack statuses count attack cards: one this card already used acts on its
		# later hits for free; one used up by an earlier card waits to be removed.
		var charged: bool = play_key != "" and buff.get_meta(ATTACK_PLAY_META, "") == play_key
		if play_key != "" and not charged and buff.is_used_up():
			continue
		var buff_is_repeating: bool = current_repeating_state and buff.can_single_turn_repeat()
		# A buff gained during this card's play doesn't react to that same play (like
		# Slay the Spire): Sharp from a card isn't used up by it, Repeat from Echo
		# doesn't repeat Echo. It acts from the next card on.
		if !buff_is_repeating and buffs_added_instance_ids.has(buff_instance_id):
			continue
		if !buff_is_repeating and buff.can_be_activated_only_once_per_turn():
			if blocked_buff_names.has(buff.get_buff_name()):
				continue
			if buff_instance_ids_activated.has(buff_instance_id) or buffs_added_instance_ids.has(buff_instance_id):
				continue

		activation_queue.append({
			'buff': buff,
			'panel': buff_panel,
			'charged': charged,
		})
		if play_key != "" and not charged:
			buff.set_meta(ATTACK_PLAY_META, play_key)
		blocked_buff_names.append(buff.get_buff_name())
		buff_instance_ids_activated.append(buff_instance_id)
		if buff_is_repeating:
			current_repeating_state = false
	return activation_queue

# ------------------------------------------- attack statuses count attack cards
# Like Slay the Spire's "your next attack": every hit of a multi-hit card (Flurry)
# gets Poison, Critical, Charge, Flame, Splinter..., and it's used up once. A
# status that acted on a card's attack remembers that play (meta); its later hits
# reuse it; it's removed (if used up) once the card's effects are done.

const ATTACK_PLAY_META := &"attack_play"

## The attack card being played right now, as "card:play number" ("" outside a play).
func _attack_play_key() -> String:
	if scene == null or not scene.has_method("get_resolving_card"):
		return ""
	var card = scene.get_resolving_card()
	if not is_instance_valid(card):
		return ""
	return "%d:%d" % [card.get_instance_id(), scene.get_card_count()]

## A card's effects are done: its attack statuses stop counting it, and the used-up
## ones go. (A Repeat replay afterwards is a new attack.)
func release_attack_statuses() -> void:
	for buff_panel in get_children():
		if not is_instance_valid(buff_panel) or buff_panel.is_queued_for_deletion() or not buff_panel.has_method("get_buff"):
			continue
		var buff: Buff = buff_panel.get_buff()
		if not is_instance_valid(buff) or not buff.has_meta(ATTACK_PLAY_META):
			continue
		buff.remove_meta(ATTACK_PLAY_META)
		if buff.is_used_up() and not buff.is_freed_manually():
			buff_panel.queue_free()

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

## Hover preview of an attack: each buff's preview in the same order as a real
## attack (tier, then the order gained). A one-shot buff (Critical, Charge, ...)
## acts once per play (context["used"]), and never more times than its uses
## (context["uses_left"]). Returns [{"panel": BuffPanel, "note": String}] for the
## buffs that would act.
func preview_buffs(activation_type: Buff.ActivationType, context: Dictionary) -> Array:
	var results: Array = []
	var panels: Array = get_children().filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion() and is_instance_valid(p.get_buff()))
	panels.sort_custom(func(a, b):
		var pa: int = a.get_buff().priority
		var pb: int = b.get_buff().priority
		return pa < pb if pa != pb else a.get_index() < b.get_index())
	if not context.has("used"):
		context["used"] = []
	if not context.has("uses_left"):
		context["uses_left"] = {}
	var names_this_attack := {}
	var charged_ids: Dictionary = context.get("charged", {})  # this card's earlier hits used these
	for panel in panels:
		var buff: Buff = panel.get_buff()
		var id: int = buff.get_instance_id()
		if not buff.matches_activation_type(activation_type):
			continue
		var per_card: bool = activation_type == Buff.ActivationType.OnAttack or activation_type == Buff.ActivationType.React
		var charged: bool = per_card and charged_ids.has(id)
		context["charged_now"] = charged
		if not charged and buff.can_be_activated_only_once_per_turn() and context["used"].has(id):
			continue
		# Like a real attack: a one-shot buff of the same name acts once per attack
		# (two Critical boxes still double just once).
		if buff.can_be_activated_only_once_per_turn() and names_this_attack.has(buff.get_buff_name()):
			continue
		var uses_left: int = context["uses_left"].get(id, buff.uses_amount)
		if not charged and not buff.is_unlimited_uses() and uses_left <= 0:
			continue
		if not charged and per_card and buff.is_used_up():
			continue
		var note: Dictionary = buff.preview_react(context) if activation_type == Buff.ActivationType.React			 else buff.preview_attack(context)
		context["charged_now"] = false
		if note.is_empty():
			continue
		if buff.can_be_activated_only_once_per_turn():
			names_this_attack[buff.get_buff_name()] = true
		if not charged:
			if buff.can_be_activated_only_once_per_turn():
				context["used"].append(id)
			if not buff.is_unlimited_uses():
				context["uses_left"][id] = uses_left - 1
			if per_card and context.has("charged"):
				context["charged"][id] = true
		results.append({"panel": panel, "note": note})
	return results

# ------------------------------------------------- one box per kind (display only)
# Same-kind buffs show as one box with the total ("Critical 2"), like Slay the
# Spire's status icons. Underneath they stay separate buffs that each act on their
# own (released puzzles depend on that), so this changes nothing but the display.

var _regroup_queued := false

func queue_regroup() -> void:
	if not _regroup_queued:
		_regroup_queued = true
		_regroup.call_deferred()

func _regroup() -> void:
	_regroup_queued = false
	var leaders := {}
	var counts := {}
	for panel in get_children():
		if not (panel is BuffPanel) or panel.is_queued_for_deletion() or not is_instance_valid(panel.get_buff()):
			continue
		var key := _group_key(panel.get_buff())
		if not leaders.has(key):
			leaders[key] = panel
			counts[key] = 0
			panel.show()
		else:
			panel.hide()
		var buff: Buff = panel.get_buff()
		counts[key] += 1 if buff.is_unlimited_uses() else maxi(buff.uses_amount, 1)
	for key in leaders:
		leaders[key].set_group_count(counts[key])

func _group_key(buff: Buff) -> String:
	return "%s|%s" % [buff.scene_file_path, buff.get_buff_name()]

## The box shown for this buff's kind (itself, or the visible one of its group).
func get_shown_panel(panel: BuffPanel) -> BuffPanel:
	if panel.visible or not is_instance_valid(panel.get_buff()):
		return panel
	var key := _group_key(panel.get_buff())
	for other in get_children():
		if other is BuffPanel and other.visible and is_instance_valid(other.get_buff()) and _group_key(other.get_buff()) == key:
			return other
	return panel
