extends RefCounted
class_name EffectRegistry
## Every card effect, as data.
##
## Effects are discovered automatically from res://Scenes/*CardEffect.tscn; an
## effect's id is its scene name without "CardEffect" ("Damage", "Draw", ...).
## Its parameters are the script's exported variables, so a new effect scene is
## usable by custom cards with no registration code.
##
## Effect definition (JSON-friendly):
##   {"type": "Damage", "params": {"damage_amount": 3}}
##   {"type": "Condition", "params": {...}, "children": [<effect>, ...]}
##   {"type": "PlayerChooseEffect", "params": {"card_effects_to_choose_from": [<effect>, ...]}}
## Only parameters that differ from the effect scene's defaults are stored.

const EFFECTS_DIR := "res://Scenes/"
const EFFECT_SUFFIX := "CardEffect.tscn"

## Parameter kinds (the "kind" field of a parameter's info).
const KIND_INT := "int"
const KIND_FLOAT := "float"
const KIND_BOOL := "bool"
const KIND_STRING := "string"
const KIND_ENUM := "enum"          # string or int with fixed options
const KIND_COLOR := "color"        # "#rrggbbaa"
const KIND_RESOURCE := "resource"  # res:// path (a scene, e.g. a card or buff)
const KIND_RESOURCES := "resources"  # list of res:// paths
const KIND_EFFECTS := "effects"    # list of nested effect definitions
const KIND_DICT := "dict"          # free-form settings, e.g. a buff's own settings (buff_params)

const TEMPLATE_LABEL_PARAMS := ["debuff_name", "target_name"]
## Gained during play, never card data.
const RUNTIME_ONLY_PARAMS := ["damage_bonus"]

## Buff settings shown up front in the builder; the rest of Buff.gd's are "advanced".
const MAIN_BUFF_BASE_PARAMS := ["uses_amount", "unlimited_uses"]

## Display settings every effect inherits from CardEffect; flagged "advanced" so a
## builder UI can tuck them away.
const BASE_EFFECT_PARAMS := ["effect_name", "effect_description", "effect_short_description",
	"requires_player_input", "effect_color", "wait_for_effect_applied", "effect_panel"]

static var _scenes: Dictionary = {}    # id -> PackedScene
static var _params: Dictionary = {}    # id -> Array[Dictionary] (parameter info)
static var _defaults: Dictionary = {}  # id -> {param: serialized default}


## All effect ids, sorted.
static func get_effect_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	ids.assign(_scenes.keys())
	ids.sort()
	return ids

static var _used_ids: Array[String] = []

## Effect ids used by at least one built-in card (directly or nested), sorted.
## The Card Builder only offers these; the rest stay available to JSON and tests.
static func get_used_effect_ids() -> Array[String]:
	if not _used_ids.is_empty():
		return _used_ids.duplicate()
	var used := {}
	var pattern := RegEx.create_from_string("path=\"res://Scenes/(\\w+)CardEffect\\.tscn\"")
	for file in DirAccess.get_files_at(EFFECTS_DIR):
		if not file.ends_with("Card.tscn") or file == "Card.tscn" or file.ends_with(EFFECT_SUFFIX):
			continue
		for found in pattern.search_all(FileAccess.get_file_as_string(EFFECTS_DIR + file)):
			used[found.get_string(1)] = true
	for id in get_effect_ids():
		if used.has(id):
			_used_ids.append(id)
	return _used_ids.duplicate()

## Effects the Card Lab offers although no built-in card uses them yet.
const CARD_LAB_EXTRA_EFFECTS := ["ReturnToHand"]
## Effects cards use that the Card Lab doesn't offer. ShowAuthor is the "designed
## by" line every community card carries, not gameplay.
const CARD_LAB_HIDDEN_EFFECTS := ["ShowAuthor", "Draw"]

## The effects the Card Lab offers: those built-in cards use, plus the extras,
## minus the hidden ones. Sorted. (The Card Lab, the effect tests and the
## watch run all use this list.)
static func get_card_lab_effect_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in get_used_effect_ids() + CARD_LAB_EXTRA_EFFECTS:
		if has_effect(id) and not id in CARD_LAB_HIDDEN_EFFECTS and not id in ids:
			ids.append(id)
	ids.sort()
	return ids

static func has_effect(id: String) -> bool:
	_ensure_loaded()
	return _scenes.has(id)

## Parameter info for an effect: [{"name", "kind", "default", "options"?}, ...]
static func get_params(id: String) -> Array:
	_ensure_loaded()
	return _params.get(id, []).duplicate(true)

## A setting's name as people read it: "damage_amount" -> "Damage Amount",
## "card_scenes" -> "Cards", "buff_scene" -> "Buff".
static func setting_label(param_name: String) -> String:
	if param_name.ends_with("_scenes"):
		param_name = param_name.trim_suffix("_scenes") + "s"  # "card_scenes" -> "Cards"
	return param_name.trim_suffix("_scene").replace("_", " ").capitalize()

## A number with its setting's name, unless the name just repeats the effect's:
## Damage's damage_amount -> "3", Discard's max_discard_amount -> "up to 1".
## Generic words (amount, count, stacks, additional) are dropped, and "max"
## becomes "up to".
static func labeled_number(type: String, param_name: String, number: String) -> String:
	var type_words := type.capitalize().to_lower().split(" ")
	var words: Array[String] = []
	var is_max := false
	for word in setting_label(param_name).split(" "):
		var lower := word.to_lower()
		if lower == "max":
			is_max = true
		elif not lower in ["amount", "count", "stacks", "additional"]:
			words.append(word)
	var prefix := "up to " if is_max else ""
	if words.all(func(w: String): return w.to_lower() in type_words):
		return prefix + number
	return " ".join(words) + " " + prefix + number

## Words for effects that have no effect_short_description of their own (the
## Pick 1 effect buttons). {setting} is that setting's value; {buff}, {debuff}
## and {card} are the chosen buff, debuff or card by name.
const SHORT_TEXT := {
	"ActivateCard": "Play a card again",
	"ActivateDiscardedCard": "Play a discarded card",
	"Buff": "Gain {buff}",
	"BuffWithHealth": "Gain {buff}",
	"ChooseReclaim": "Reclaim up to {max_reclaim_amount}",
	"Condition": "If ..., then ...",
	"CreateCard": "Create {card}",
	"Damage": "Deal {damage_amount} damage",
	"Debuff": "Inflict {stacks} {debuff}",
	"Discard": "Discard up to {max_discard_amount}",
	"Draw": "Draw {draw_amount}",
	"FreeBuff": "Gain {buff}",
	"GainEnergy": "Gain {additional_energy_amount} energy",
	"GainEnergyBasedOnCardsPlayed": "Gain energy per card played",
	"Heal": "Heal {heal_amount}",
	"HealEnemy": "Enemy heals {heal_amount}",
	"HealEnemyGainEnergy": "Enemy heals {heal_amount}, gain energy",
	"HealthToDebuff": "Turn HP into {debuff}",
	"IncreaseDamageModify": "+{damage_increase_amount} damage",
	"IncreaseDamageSpecificCardModify": "+{damage_increase_amount} damage to {target_card_name}",
	"LoseEnergy": "Lose {energy_amount_loss} energy",
	"PickToCreate": "Create up to {max_pick_amount} cards",
	"PlayerChooseEffect": "Choose an effect",
	"Reclaim": "Reclaim {card_amount}",
	"ReclaimIfHandEmpty": "Reclaim {card_amount} if your hand is empty",
	"ReduceHealth": "Lose {reduce_amount} HP",
	"RemoveBuffs": "Remove buffs",
	"RepeatBuff": "Gain {buff}",
	"ReturnToHand": "Return to hand",
	"SetEnergy": "Set energy to {energy_amount}",
	"SetHealth": "Set HP to {health_amount}",
	"SharpenBasedOnCardsPlayed": "Gain {buff}",
	"SwapHealthAndEnergy": "Swap HP and energy",
	"Trash": "Trash {card_amount}",
	"TrashChoose": "Trash up to {max_trash_amount}",
	"TrashDiscardEndsAndReclaim": "Trash and reclaim",
}

## A short line for an effect that has no effect_short_description of its own:
## "Draw 2", "Gain Sharp 2", "Inflict 3 Burn". Other effects: their name.
static func short_text(effect: Node) -> String:
	var type := get_effect_id(effect)
	var text: String = SHORT_TEXT.get(type, "")
	if text.is_empty():
		var effect_name = effect.get("effect_name")
		if effect_name is String and not effect_name.is_empty():
			return effect_name
		return type.capitalize() if not type.is_empty() else "Effect"
	for token in ["buff", "debuff", "card"]:
		var scene_value = effect.get(token + "_scene") if token != "card" else effect.get("card_to_create_scene")
		text = text.replace("{%s}" % token, _scene_word(scene_value, token))
	if type in ["Buff", "BuffWithHealth", "FreeBuff", "RepeatBuff", "SharpenBasedOnCardsPlayed"]:
		var amount := _buff_amount(effect.get("buff_params"))
		if amount > 0:
			text += " %d" % amount
	var found := RegEx.create_from_string("\\{([a-z_]+)\\}").search_all(text)
	for match_result in found:
		var value = effect.get(match_result.get_string(1))
		text = text.replace(match_result.get_string(0), str(int(value)) if value is int or value is float else str(value) if value != null else "")
	return text.strip_edges().trim_suffix(" to")

## "res://Scenes/SharpBuff.tscn" -> "Sharp"; nothing chosen -> the word itself.
static func _scene_word(value, fallback: String) -> String:
	var path := ""
	if value is Resource:
		path = value.resource_path
	elif value is String:
		path = value
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		path = ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else ""
	var word := path.get_file().get_basename()
	if path.contains("::") and value is PackedScene and value.get_state().get_node_count() > 0:
		word = str(value.get_state().get_node_name(0))  # a scene inside another: its root's name
	if word.is_empty():
		return fallback.capitalize()
	return word.trim_suffix("Debuff").trim_suffix("Buff").trim_suffix("Card").capitalize()

## A buff effect's own amount (Sharp's sharp_count, ...), or 0.
static func _buff_amount(buff_params) -> int:
	if buff_params is Dictionary:
		for setting in buff_params:
			if buff_params[setting] is int or buff_params[setting] is float:
				return int(buff_params[setting])
	return 0

## Effect id for an effect instance ("Damage" for a DamageCardEffect).
static func get_effect_id(effect: Node) -> String:
	var scene_path: String = effect.scene_file_path
	if scene_path.ends_with(EFFECT_SUFFIX):
		return scene_path.get_file().trim_suffix(EFFECT_SUFFIX)
	return ""

## Builds an effect (not yet in the tree) from a definition. Nested effects named
## by an effects-list parameter are returned in `siblings`: the caller adds them
## next to this effect (e.g. Potion's Heal/Damage options sit beside its
## PlayerChooseEffect). Returns null for an unknown type.
static func create_effect(definition: Dictionary, siblings: Array = []) -> CardEffect:
	_ensure_loaded()
	var id: String = str(definition.get("type", ""))
	if not _scenes.has(id):
		push_warning("EffectRegistry: unknown effect type '%s'" % id)
		return null
	var effect: CardEffect = _scenes[id].instantiate()
	var params: Dictionary = definition.get("params", {})
	for info: Dictionary in _params[id]:
		var param_name: String = info["name"]
		if not params.has(param_name):
			continue
		var value = params[param_name]
		if info["kind"] == KIND_EFFECTS:
			var nested: Array[CardEffect] = []
			for nested_definition in value:
				var nested_effect := create_effect(nested_definition, siblings)
				if nested_effect != null:
					nested.append(nested_effect)
					siblings.append(nested_effect)
			effect.set(param_name, nested)
		elif info["kind"] == KIND_RESOURCES:
			# Keep the property's typed-array type (Array[Resource], Array[PackedScene], ...).
			var resources: Array = effect.get(param_name).duplicate()
			resources.clear()
			for entry in (value if value is Array else []):
				var path := allowed_scene_path(param_name, str(entry))
				if not path.is_empty():
					resources.append(load(path))
			effect.set(param_name, resources)
		elif info["kind"] == KIND_DICT and param_name == "buff_params":
			# buff_scene comes earlier in the list, so the effect already holds the chosen buff.
			effect.set(param_name, _buff_settings_from_data(str(effect.get("buff_scene")), value))
		else:
			effect.set(param_name, _deserialize(info, value))
	for child_definition in definition.get("children", []):
		var child := create_effect(child_definition, siblings)
		if child != null:
			effect.add_child(child, true)
	return effect

## The definition of an effect instance (inverse of create_effect).
static func describe_effect(effect: Node) -> Dictionary:
	_ensure_loaded()
	var id := get_effect_id(effect)
	var definition := {"type": id}
	if not _scenes.has(id):
		return definition
	var params := {}
	for info: Dictionary in _params[id]:
		var param_name: String = info["name"]
		var value = _serialize(info, effect.get(param_name))
		if value == null or value == _defaults[id].get(param_name):
			continue
		params[param_name] = value
	if not params.is_empty():
		definition["params"] = params
	# Built-in cards may configure their buff with a Buff child node (buff_node, e.g.
	# Sharpen's SharpBuff with sharp_count 3); store that as the buff and its settings.
	var buff_node = effect.get("buff_node")
	if buff_node is Buff and not buff_node.scene_file_path.is_empty() and not params.has("buff_params"):
		params["buff_scene"] = scene_name(buff_node.scene_file_path)
		var buff_settings := describe_scene_settings(buff_node)
		if not buff_settings.is_empty():
			params["buff_params"] = buff_settings
		definition["params"] = params
	var children: Array = []
	for child in effect.get_children():
		if child is CardEffect:
			children.append(describe_effect(child))
	if not children.is_empty():
		definition["children"] = children
	return definition


static func _ensure_loaded() -> void:
	if not _scenes.is_empty():
		return
	for file in DirAccess.get_files_at(EFFECTS_DIR):
		if not file.ends_with(EFFECT_SUFFIX):
			continue
		var id := file.trim_suffix(EFFECT_SUFFIX)
		var scene: PackedScene = load(EFFECTS_DIR + file)
		if scene == null:
			continue
		var instance = scene.instantiate()
		if not (instance is CardEffect):
			instance.free()
			continue
		_scenes[id] = scene
		_params[id] = []
		_defaults[id] = {}
		for property in instance.get_property_list():
			var info := _param_info(property)
			if info.is_empty():
				continue
			var default_value = _serialize(info, instance.get(property["name"]))
			info["default"] = default_value
			_params[id].append(info)
			_defaults[id][info["name"]] = default_value
		instance.free()

## Parameter info for an exported script property, or {} if it isn't data
## (node references are wired up at runtime, not stored).
static func _param_info(property: Dictionary) -> Dictionary:
	var usage: int = property["usage"]
	if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (usage & PROPERTY_USAGE_STORAGE)			 or property["name"] in RUNTIME_ONLY_PARAMS:
		return {}
	# card_lab_* (and Debuff's debuff_name/target_name) only label the Card Lab's
	# template values; they don't change what the effect does.
	var advanced: bool = property["name"] in BASE_EFFECT_PARAMS or property["name"] in TEMPLATE_LABEL_PARAMS \
		or str(property["name"]).begins_with("card_lab_")
	var info := {"name": property["name"], "advanced": advanced}
	var hint: int = property["hint"]
	var hint_string: String = property["hint_string"]
	match property["type"]:
		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				info["kind"] = KIND_ENUM
				info["options"] = _enum_options(hint_string)
			else:
				info["kind"] = KIND_INT
		TYPE_FLOAT:
			info["kind"] = KIND_FLOAT
		TYPE_BOOL:
			info["kind"] = KIND_BOOL
		TYPE_STRING:
			if hint == PROPERTY_HINT_ENUM:
				info["kind"] = KIND_ENUM
				info["options"] = _enum_options(hint_string)
			elif hint == PROPERTY_HINT_FILE:
				info["kind"] = KIND_RESOURCE
				info["stored_as_path"] = true
			else:
				info["kind"] = KIND_STRING
		TYPE_COLOR:
			info["kind"] = KIND_COLOR
		TYPE_DICTIONARY:
			info["kind"] = KIND_DICT
		TYPE_OBJECT:
			if hint_string == "PackedScene" or hint_string == "Resource":
				info["kind"] = KIND_RESOURCE
			else:
				return {}  # Node, Card, Buff, ... references
		TYPE_ARRAY:
			if hint_string.ends_with("CardEffect"):
				info["kind"] = KIND_EFFECTS
			elif hint_string.ends_with(":Resource") or hint_string.ends_with(":PackedScene"):
				info["kind"] = KIND_RESOURCES
			else:
				return {}
		_:
			return {}
	# Scenes are data only when they come from a pick list (buffs, debuffs, cards),
	# stored by name. Anything else (e.g. effect_panel) isn't card data.
	if info["kind"] in [KIND_RESOURCE, KIND_RESOURCES] and get_resource_choices(info["name"]).is_empty():
		return {}
	return info

static func _enum_options(hint_string: String) -> Array:
	var options: Array = []
	for option in hint_string.split(","):
		options.append(option.get_slice(":", 0).strip_edges())
	return options

static func _serialize(info: Dictionary, value):
	match info["kind"]:
		KIND_COLOR:
			return "#" + (value as Color).to_html(true)
		KIND_RESOURCE:
			var path: String = value.resource_path if value is Resource else (value if value is String else "")
			var name := scene_name(path)
			return name if not name.is_empty() else null
		KIND_DICT:
			return (value as Dictionary).duplicate(true) if value is Dictionary else {}
		KIND_RESOURCES:
			var names: Array = []
			for item in value:
				if item is Resource:
					var name := scene_name(item.resource_path)
					if not name.is_empty():
						names.append(name)
			return names
		KIND_EFFECTS:
			var nested: Array = []
			for item in value:
				if item is CardEffect:
					nested.append(describe_effect(item))
			return nested
	return value

## "uid://bwpfxrgdwe5gw" -> "res://Scenes/SharpBuff.tscn" (card scenes store some
## paths as UIDs; card data uses readable paths).
static func _readable_path(path: String) -> String:
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return path


# ------------------------------------------------------------ pickable scenes

static var _choices: Dictionary = {}  # category -> [{"label", "path"}]
static var _scene_params: Dictionary = {}  # scene path -> parameter info

## What a resource parameter can be set to, by its name: buffs for "buff_scene",
## debuffs for "debuff_scene", cards for "card_to_create_scene". Returns
## [{"label": "Sharp", "path": "res://Scenes/SharpBuff.tscn"}, ...], or [] when
## the parameter isn't one of those (the builder shows a text field).
static func get_resource_choices(param_name: String) -> Array:
	var category := ""
	if param_name.contains("debuff"):
		category = "Debuff"
	elif param_name.contains("buff"):
		category = "Buff"
	elif param_name.contains("card"):
		category = "Card"
	if category.is_empty():
		return []
	if not _choices.has(category):
		var choices: Array = []
		var suffix := category + ".tscn"
		for file in DirAccess.get_files_at(EFFECTS_DIR):
			# "BurnDebuff.tscn" doesn't end with "Buff.tscn" (lowercase b), so the lists don't overlap.
			if not file.ends_with(suffix) or file == suffix or file.ends_with(EFFECT_SUFFIX):
				continue
			var choice_id := file.trim_suffix(suffix)
			choices.append({"id": choice_id, "label": choice_id.capitalize(), "path": EFFECTS_DIR + file})
		choices.sort_custom(func(a, b): return a["label"] < b["label"])
		_choices[category] = choices
	return _choices[category].duplicate(true)

static var _card_buff_targets: Dictionary = {}  # buff scene path -> "Player"/"Enemy"

## The buffs built-in cards give, and who each goes on: {"res://Scenes/SharpBuff.tscn":
## "Player", "res://Scenes/CorrodeBuff.tscn": "Enemy", ...}. Buffs are the player's
## except Corrode, which the Corrode card puts on the enemy. Buffs no card gives
## (enemy puzzle abilities like Doom and Retaliate, the ModifyAttack interface)
## aren't in it, so the Card Lab doesn't offer them.
static func get_card_buff_targets() -> Dictionary:
	if _card_buff_targets.is_empty():
		var buff_pattern := RegEx.create_from_string("buff_scene = \"([^\"]+)\"")
		var target_pattern := RegEx.create_from_string("buff_auto_target = \"(\\w*)\"")
		for file in DirAccess.get_files_at(EFFECTS_DIR):
			if not file.ends_with("Card.tscn") or file == "Card.tscn" or file.ends_with(EFFECT_SUFFIX):
				continue
			for block in FileAccess.get_file_as_string(EFFECTS_DIR + file).split("\n[node "):
				var buff := buff_pattern.search(block)
				if buff == null:
					continue
				var path := _readable_path(buff.get_string(1))
				if not path.ends_with("Buff.tscn"):
					continue  # a debuff (Vulnerable, Burn): those come from the Debuff effect
				var target := target_pattern.search(block)
				var who := target.get_string(1) if target != null and not target.get_string(1).is_empty() else "Player"
				if not _card_buff_targets.has(path) or who == "Enemy":
					_card_buff_targets[path] = who
	return _card_buff_targets.duplicate()

## The buffs the Card Lab offers: those some built-in card gives.
static func get_offered_buff_choices() -> Array:
	var targets := get_card_buff_targets()
	return get_resource_choices("buff_scene").filter(func(c): return targets.has(c["path"]))

## Who a buff goes on when a card gives it ("Player" unless it's Corrode-like).
static func get_buff_target(buff_value: String) -> String:
	var path := allowed_scene_path("buff_scene", buff_value) if not buff_value.is_empty() else ""
	return get_card_buff_targets().get(path, "Player")

## The scene path card data may use for a setting, or "" if it isn't allowed.
## Card data names scenes ("Sharp", "Spark"); older data used paths, which are
## accepted only when they point at one of the same scenes (".scn", the pre-text
## format, and uid:// forms too). Nothing outside the pick list is ever loaded.
static func allowed_scene_path(param_name: String, value: String) -> String:
	var wanted := value.strip_edges()
	if wanted.begins_with("uid://"):
		wanted = _readable_path(wanted)
	if wanted.ends_with(".scn"):
		wanted = wanted.get_basename() + ".tscn"
	for choice: Dictionary in get_resource_choices(param_name):
		if wanted == choice["path"] or wanted == choice["id"] or wanted == choice["label"] \
				or wanted == choice["path"].get_file().get_basename():
			return choice["path"]
	if not wanted.is_empty():
		push_warning("EffectRegistry: '%s' isn't an allowed %s; ignored" % [value, param_name])
	return ""

## "res://Scenes/SharpBuff.tscn" -> "Sharp", the name card data uses ("" if the
## path isn't a buff, debuff or card scene).
static func scene_name(path: String) -> String:
	var readable := _readable_path(path)
	for category_param in ["debuff_scene", "buff_scene", "card_scene"]:
		for choice: Dictionary in get_resource_choices(category_param):
			if choice["path"] == readable:
				return choice["id"]
	return ""

## A buff's settings from card data: only that buff's own settings, as numbers,
## booleans or text (nothing that names a node, script or file).
static func _buff_settings_from_data(buff_value, settings) -> Dictionary:
	var result := {}
	var buff_path := allowed_scene_path("buff_scene", str(buff_value))
	if buff_path.is_empty() or not (settings is Dictionary):
		return result
	for info: Dictionary in get_scene_params(buff_path):
		var setting: String = info["name"]
		if settings.has(setting) and info["kind"] in [KIND_INT, KIND_FLOAT, KIND_BOOL, KIND_STRING, KIND_ENUM, KIND_COLOR]:
			result[setting] = _deserialize(info, settings[setting])
	return result

## The settings of a buff (or any scene): its script's exported data, as parameter
## info like get_params(). For buffs, Buff.gd's shared settings other than
## MAIN_BUFF_BASE_PARAMS are flagged "advanced".
static func get_scene_params(scene_path: String) -> Array:
	if not _scene_params.has(scene_path):
		var infos: Array = []
		var scene = load(scene_path) if ResourceLoader.exists(scene_path) else null
		if scene is PackedScene:
			var instance: Node = scene.instantiate()
			var base_names := {}
			if instance is Buff:
				for property in (load("res://Scripts/Buff.gd") as Script).get_script_property_list():
					base_names[property["name"]] = true
			for property in instance.get_property_list():
				var info := _param_info(property)
				if info.is_empty() or info["kind"] == KIND_DICT:
					continue
				info["advanced"] = base_names.has(info["name"]) and not info["name"] in MAIN_BUFF_BASE_PARAMS
				info["default"] = _serialize(info, instance.get(property["name"]))
				infos.append(info)
			instance.free()
		_scene_params[scene_path] = infos
	return _scene_params[scene_path].duplicate(true)

## A scene instance's settings that differ from its scene's defaults.
static func describe_scene_settings(node: Node) -> Dictionary:
	var settings := {}
	for info: Dictionary in get_scene_params(node.scene_file_path):
		var value = _serialize(info, node.get(info["name"]))
		if value != null and value != info["default"]:
			settings[info["name"]] = value
	return settings

static func _deserialize(info: Dictionary, value):
	match info["kind"]:
		KIND_INT:
			return int(value)
		KIND_FLOAT:
			return float(value)
		KIND_BOOL:
			return bool(value)
		KIND_ENUM:
			return int(value) if value is float else value
		KIND_COLOR:
			return Color.html(str(value))
		KIND_RESOURCE:
			# Only scenes from the pick list; @export_file properties hold the path,
			# PackedScene/Resource ones the loaded scene.
			var path := allowed_scene_path(info["name"], str(value))
			if path.is_empty():
				return "" if info.get("stored_as_path", false) else null
			return path if info.get("stored_as_path", false) else load(path)
	return value
