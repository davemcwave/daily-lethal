extends CardEffect

@export_file("*.scn") var debuff_scene
@export var stacks: int = 1
@export var target: Node = null
var debuff_template: Debuff = null
var debuff_scene_resource: PackedScene = null
var template_values: Dictionary = {}
@export var debuff_name: String = ""
@export var target_name: String = "Enemy"

func _ready() -> void:
	_ensure_target()
	_ensure_debuff_template()

func get_effect_name() -> String:
	_ensure_debuff_template()
	if debuff_template == null:
		return name
	return debuff_template.get_debuff_name()

func set_debuff_scene(new_debuff) -> void:
	if typeof(new_debuff) == TYPE_STRING:
		debuff_scene = new_debuff
		debuff_scene_resource = null
		debuff_template = null
		_ensure_debuff_template()
	elif new_debuff is PackedScene:
		debuff_scene_resource = new_debuff
		debuff_scene = new_debuff.resource_path
		debuff_template = null
		_ensure_debuff_template()
	elif new_debuff is Debuff:
		debuff_template = new_debuff
		if new_debuff.scene_file_path != "":
			debuff_scene = new_debuff.scene_file_path

func get_effect_description() -> String:
	_ensure_debuff_template()
	if debuff_template == null:
		return ""
	return debuff_template.get_debuff_description()

func set_template_values(values: Dictionary) -> void:
	template_values = values.duplicate(true)
	debuff_name = str(template_values.get("debuff", debuff_name))
	stacks = int(template_values.get("stacks", stacks))
	target_name = str(template_values.get("target", target_name))

func get_template_values() -> Dictionary:
	return template_values.duplicate(true)

func set_card_lab_template_values(values: Dictionary) -> void:
	set_template_values(values)

func get_card_lab_template_values() -> Dictionary:
	return get_template_values()

func get_status_effect() -> Dictionary:
	return {
		"name": debuff_name,
		"stacks": stacks,
		"target": target_name,
		"params": get_template_values()
	}

func set_target(new_target) -> void:
	target = new_target
	_ensure_target()

func apply() -> bool:
	_ensure_target()
	_ensure_debuff_template()
	if debuff_template == null:
		push_warning("DebuffCardEffect has no debuff template to apply.")
		return false
	var debuff_instance: Debuff = debuff_template.duplicate(DUPLICATE_USE_INSTANTIATION)
	debuff_instance.set_stacks(stacks)
	print(target)
	target.add_debuff(debuff_instance)
	return super.apply()

func _ensure_debuff_template() -> void:
	if debuff_template != null:
		return
	for child in get_children():
		if child is Debuff:
			debuff_template = child
			return
	_load_debuff_scene()
	if debuff_scene_resource != null:
		debuff_template = debuff_scene_resource.instantiate()

func _load_debuff_scene() -> void:
	if debuff_scene_resource != null:
		return
	if typeof(debuff_scene) == TYPE_STRING and not debuff_scene.is_empty():
		var packed = load(debuff_scene)
		if packed is PackedScene:
			debuff_scene_resource = packed

func _ensure_target() -> void:
	if target == null or not is_instance_valid(target) or target is CardEffect:
		var enemy = get_tree().get_root().get_node_or_null("Scene/Enemy")
		if enemy != null:
			target = enemy
