extends CardEffect
class_name BuffCardEffect

@export_file("*.tscn") var buff_scene
@export var buff_node: Buff = null
var buff: Buff = null
@export_enum("Player", "Enemy") var buff_auto_target: String = "Player"  # empty used to mean Player too
@export var defer_add_until_after_card_play: bool = false
var buff_color: Color = Color.WHITE
## Settings applied to the buff (e.g. {"sharp_count": 3}); custom cards set these.
@export var buff_params: Dictionary = {}
var card_lab_template_values: Dictionary = {}
@export var card_lab_buff_name: String = ""
@export var card_lab_buff_stacks: int = 1
@export var card_lab_buff_target: String = ""

func _ready() -> void:
	buffs_container = get_tree().get_root().get_node("Scene/BuffsContainer")
	reset_buff()

func set_buff_auto_target(new_buff_auto_target: String) -> void:
	buff_auto_target = new_buff_auto_target

func get_effect_name() -> String:
	if buff == null:
		return name
	else:
		return buff.get_buff_name()
	#
func get_effect_description() -> String:
	return buff.get_buff_description() if buff != null else ""
	
func set_buff_color(new_buff_color: Color) -> void:
	buff_color = new_buff_color

func set_buff(new_buff: Buff) -> void:
	buff = new_buff

func set_buff_scene(new_buff_scene: String) -> void:
	buff_scene = new_buff_scene

func set_buff_params(new_buff_params: Dictionary) -> void:
	buff_params = new_buff_params.duplicate()

func get_buff_params() -> Dictionary:
	return buff_params.duplicate()

func set_card_lab_template_values(values: Dictionary) -> void:
	card_lab_template_values = values.duplicate(true)
	card_lab_buff_name = str(card_lab_template_values.get("buff", card_lab_buff_name))
	card_lab_buff_stacks = int(card_lab_template_values.get("stacks", card_lab_buff_stacks))
	card_lab_buff_target = str(card_lab_template_values.get("target", card_lab_buff_target))

func get_card_lab_template_values() -> Dictionary:
	return card_lab_template_values.duplicate(true)

func get_status_effect() -> Dictionary:
	return {
		"name": card_lab_buff_name,
		"stacks": card_lab_buff_stacks,
		"target": card_lab_buff_target,
		"params": get_card_lab_template_values()
	}

func get_buff() -> Buff:
	return buff
	
func reset_buff() -> void:
	if buff_node != null:
		buff = buff_node
	elif buff_scene is String and ResourceLoader.exists(buff_scene):
		buff = load(buff_scene).instantiate()
	else:
		# No buff chosen (a custom card left "Choose..."): the effect does nothing.
		buff = null
		push_warning("%s: no buff chosen; this effect does nothing" % name)
		return
	if buff != null:
		_apply_params_to_buff(buff, buff_params)

	if buff_auto_target == "Player":
		buff.set_target(get_tree().get_root().get_node("Scene/Health")) 
	elif buff_auto_target == "Enemy":
		buff.set_target(get_tree().get_root().get_node("Scene/Enemy")) 
	else:
		buff.set_target(get_tree().get_root().get_node("Scene/Health")) 
	
func apply() -> bool:
	if buff == null:
		return super.apply()  # no buff chosen
	audio_handler.play_sfx("AddBuffSFX")
	audio_handler.increase_pitch_scale("AddBuffSFX", 0.25)

	var target = buff.get_target()
	var buff_instance: Buff = buff.duplicate(DUPLICATE_USE_INSTANTIATION)
	if get_parent() is Card:
		buff_instance.set_source_card(get_parent())

	if target is Health:
		if defer_add_until_after_card_play:
			call_deferred("_deferred_add_player_buff", buff_instance)
		else:
			buffs_container.add_buff(buff_instance)
	elif target is Enemy:
		if defer_add_until_after_card_play:
			call_deferred("_deferred_add_enemy_buff", target, buff_instance)
		else:
			target.add_buff(buff_instance)

	return super.apply()

func _deferred_add_player_buff(buff_instance: Buff) -> void:
	if buffs_container != null and is_instance_valid(buffs_container):
		buffs_container.add_buff(buff_instance)

func _deferred_add_enemy_buff(enemy, buff_instance: Buff) -> void:
	if enemy != null and is_instance_valid(enemy):
		enemy.add_buff(buff_instance)

func _apply_params_to_buff(target_buff: Buff, params: Dictionary) -> void:
	if target_buff == null or params.is_empty():
		return
	# Only the buff's own plain settings (numbers, true/false, text, colors): card
	# data must never set a script, node or resource through here.
	var property_lookup := {}
	for property in target_buff.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_COLOR]:
			property_lookup[property.name] = property.type

	for key in params.keys():
		var value = params[key]
		if property_lookup.has(key):
			# Card data comes from JSON: numbers arrive as floats, colors as "#rrggbb".
			match property_lookup[key]:
				TYPE_INT:
					value = int(value)
				TYPE_COLOR:
					if value is String:
						value = Color.html(value)
			target_buff.set(key, value)
		# Anything else is ignored (no set_<name>() fallback: that could reach set_script).
