extends RichTextLabel
class_name URLCapturer

var puzzle_date: String = ""
var path_name
var search
var card_list = ""
var custom_cards_data: Array = []
var card_order_tokens: Array = []
var puzzle_creator_name: String = ""
var enemy_name_override: String = ""
var enemy_buffs_url_data: Array = []

# DEBUG: Set this to test custom cards in the Godot editor
@export var debug_custom_cards_json: String = ""

func _ready():
	path_name = JavaScriptBridge.eval("window.location.pathname")
	search = JavaScriptBridge.eval("window.location.search")
	# Off the web (editor, desktop, test runner) there is no URL; use the one
	# Background was given via --url= or by the puzzle test runner. A puzzle started
	# inside the game (a Puzzle Lab test, a Library puzzle) uses it on the web too: the
	# page's own address is /desktop/?puzzle_lab=1 or ?library=1. A Library scene puzzle
	# has none, so Scene falls back to Background's puzzle scene.
	var background = get_node_or_null("/root/Background")
	var no_url: bool = (search == null or str(search).is_empty()) and not OS.has_feature("web")
	var in_game: bool = background != null and (background.card_builder_trying or background.is_from_archive())
	if background != null and (in_game or (no_url and not background.url_override_search.is_empty())):
		path_name = background.url_override_path
		search = background.url_override_search
	puzzle_creator_name = _get_query_param("puzzle_creator")
	if puzzle_creator_name.is_empty():
		puzzle_creator_name = _get_query_param("creator")
	if puzzle_creator_name.is_empty():
		puzzle_creator_name = _get_query_param("author")
	if puzzle_creator_name.is_empty():
		puzzle_creator_name = _get_query_param("credit_name")

	enemy_name_override = _get_query_param("enemy_name")
	if enemy_name_override.is_empty():
		enemy_name_override = _get_query_param("enemy")
	if enemy_name_override.is_empty():
		enemy_name_override = _get_query_param("enemy_info")

	# DEBUG: If running in editor with debug JSON, use that instead
	if not debug_custom_cards_json.is_empty():
		var json = JSON.new()
		if json.parse(debug_custom_cards_json) == OK:
			custom_cards_data = json.get_data()
			print("DEBUG: Loaded %d custom cards from debug JSON" % custom_cards_data.size())
	# Parse custom cards if present in URL
	elif has_custom_cards():
		_parse_custom_cards()

	if search != null and "card_order=" in search:
		_parse_card_order()

	_parse_enemy_buffs()

	var query_puzzle_date := _get_query_param("puzzle_date")
	if not query_puzzle_date.is_empty():
		puzzle_date = query_puzzle_date
	else:
		var path_puzzle_date := _extract_puzzle_date_from_path(path_name)
		if not path_puzzle_date.is_empty():
			puzzle_date = path_puzzle_date

	# Debug: bring to front and show URL parsing info
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	#show()
	update_label()

func has_puzzle_date() -> bool:
	#var puzzle_date_from_search = get_puzzle_date_from_search() 
	#return puzzle_date_from_search != null and "-" in puzzle_date_from_search
	return puzzle_date != null and puzzle_date != "" and "-" in puzzle_date

func has_today() -> bool:
	return puzzle_date == "today"
	
func is_test_puzzle() -> bool:
	return search != null and "?cards=" in search

func get_player_energy_from_test_puzzle() -> int:
	return int(search.split("&pnrg=")[-1].split("&")[0])
	
func get_player_health_from_test_puzzle() -> int:
	return int(search.split("&php=")[-1].split("&")[0])
	
func get_energy_health_from_test_puzzle() -> int:
	return int(search.split("&ehp=")[-1].split("&")[0])
	
func get_enemy_name_from_test_puzzle() -> String:
	return enemy_name_override if not enemy_name_override.is_empty() else "Enemy"
	
func get_cards_from_test_puzzle() -> Array:
	var cards: Array = []
	#set_text("[center][b]%s[/b][/center]" % search)

	var base64_encoded_card_list = search.split("?cards=")[-1].split("&")[0]
	var card_list_url_decoded = base64_encoded_card_list.uri_decode()
	var card_list_base64_decoded = Marshalls.base64_to_utf8(card_list_url_decoded)
	card_list = card_list_base64_decoded
	var card_string = card_list_base64_decoded.uri_decode()
	var card_path_strings = card_string.split(",")
	var card_scene_paths = []
	for card_path_string: String in card_path_strings:
		# card_path_string = "lunge-card.PNG"; empty when a puzzle has only custom cards
		if card_path_string.strip_edges().is_empty():
			continue
		var card_path_no_png: String = card_path_string.replace(".PNG", "")
		var card_path_two_words = card_path_no_png.split("-")
		var card_first_word = card_path_two_words[0].capitalize()
		var card_second_word = card_path_two_words[1].capitalize()
		var card_scene_path = "res://Scenes/%s%s.tscn" % [card_first_word, card_second_word]
		# The link names cards; only the game's own card scenes are dealt.
		if EffectRegistry.allowed_scene_path("card_scene", card_scene_path).is_empty():
			continue
		var card_packed_scene = load(card_scene_path)

		card_scene_paths.append(card_scene_path)
		cards.append(card_packed_scene)
		#set_text("[center][b]%s[/b][/center]" % ",".join(card_scene_paths))
		
	#update_label()
	
	return cards

	
func get_puzzle_date() -> String:
	return puzzle_date

func get_path_name() -> String:
	return path_name

func update_label() -> void:
	var debug_info = "search: %s\nhas_custom: %s\ndata: %s" % [
		str(search).substr(0, 100) if search != null else "NULL",
		has_custom_cards(),
		str(custom_cards_data)
	]
	set_text("[b]%s[/b]" % debug_info)

func has_puzzle_creator_name() -> bool:
	return not puzzle_creator_name.is_empty()

func get_puzzle_creator_name() -> String:
	return puzzle_creator_name

func _get_query_param(param_name: String) -> String:
	if search == null or param_name.is_empty():
		return ""
	var query_string: String = str(search)
	if query_string.begins_with("?"):
		query_string = query_string.substr(1, query_string.length() - 1)
	var pairs: PackedStringArray = query_string.split("&", false)
	for pair in pairs:
		if pair.is_empty():
			continue
		var key_value = pair.split("=", true, 1)
		if key_value.size() == 0:
			continue
		if key_value[0] != param_name:
			continue
		if key_value.size() == 1:
			return ""
		return key_value[1].uri_decode()
	return ""

func _extract_puzzle_date_from_path(path_value) -> String:
	if path_value == null:
		return ""
	var normalized = str(path_value).lstrip("/").rstrip("/")
	if normalized.is_empty():
		return ""
	var segments := normalized.split("/")
	for i in range(segments.size() - 1, -1, -1):
		var candidate: String = segments[i]
		if _is_valid_puzzle_date(candidate):
			return candidate
	return ""

func _is_valid_puzzle_date(value: String) -> bool:
	if value.length() != 10:
		return false
	var parts := value.split("-")
	if parts.size() != 3:
		return false
	if parts[0].length() != 4 or parts[1].length() != 2 or parts[2].length() != 2:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
	return true

# ============================================
# CUSTOM CARDS FROM CARD LAB
# ============================================

func has_custom_cards() -> bool:
	# Check debug data first, then URL
	return custom_cards_data.size() > 0 or (search != null and "custom_cards=" in search)

func has_card_order() -> bool:
	return card_order_tokens.size() > 0

func _parse_custom_cards() -> void:
	var base64_encoded = search.split("custom_cards=")[-1].split("&")[0]
	var url_decoded = base64_encoded.uri_decode()
	var json_string = Marshalls.base64_to_utf8(url_decoded)

	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		custom_cards_data = json.get_data()
	else:
		push_error("Failed to parse custom cards JSON: " + json.get_error_message())

func get_custom_cards_data() -> Array:
	return custom_cards_data

func _parse_card_order() -> void:
	if search == null or not ("card_order=" in search):
		return

	var base64_encoded = search.split("card_order=")[-1].split("&")[0]
	if base64_encoded.is_empty():
		return

	var url_decoded = base64_encoded.uri_decode()
	var json_string = Marshalls.base64_to_utf8(url_decoded)

	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		var data = json.get_data()
		if data is Array:
			card_order_tokens.clear()
			for token in data:
				card_order_tokens.append(str(token))
		else:
			push_error("Card order JSON must be an array.")
	else:
		push_error("Failed to parse card order JSON: " + json.get_error_message())

func get_card_order_tokens() -> Array:
	return card_order_tokens.duplicate()

func has_enemy_buffs_from_url() -> bool:
	return enemy_buffs_url_data.size() > 0

func get_enemy_buffs_from_url() -> Array:
	return enemy_buffs_url_data.duplicate()

func _parse_enemy_buffs() -> void:
	var raw := _get_query_param("enemy_buffs")
	if raw.is_empty():
		return
	for token in raw.split(","):
		token = token.strip_edges()
		if token.is_empty():
			continue
		var parts := token.split(":")
		var buff_name := parts[0].strip_edges()
		var params := {}
		if parts.size() >= 2:
			var second := parts[1].strip_edges()
			if second.is_valid_int():
				params["value"] = int(second)
		enemy_buffs_url_data.append({"name": buff_name, "params": params})

func create_custom_cards() -> Array:
	var cards: Array = []

	print("DEBUG create_custom_cards: custom_cards_data.size() = %d" % custom_cards_data.size())
	print("DEBUG create_custom_cards: custom_cards_data = %s" % str(custom_cards_data))

	for card_index in custom_cards_data.size():
		var card_data = custom_cards_data[card_index]
		print("DEBUG: Processing card_data: %s" % str(card_data).substr(0, 50))
		var card: Card = load("res://Scenes/Card.tscn").instantiate()
		print("DEBUG: Instantiated card: %s" % (card if card else "NULL"))
		if card:
			_configure_card(card, card_data)
			print("DEBUG: Configured card name: %s" % card.card_name)
			card.set_meta("card_order_token", "C%d" % card_index)
			card.set_meta("card_order_source", "custom")
			card.set_meta("card_order_index", card_index)
			cards.append(card)
		else:
			print("DEBUG: Failed to instantiate EmptyCard!")

	return cards

func _configure_card(card: Card, data: Dictionary) -> void:
	# Built the same way as every other card. Effect types from the registry
	# ("Damage", "Condition", ...) work directly; the Card Lab's original types
	# ("DamageCardEffect" with "damage", ...) still go through
	# _create_effect_from_data so existing links behave exactly as before.
	CardFactory.apply_definition(card, data, _create_effect_from_data)

func _create_effect_from_data(effect_data: Dictionary):
	var effect_type: String = effect_data.get("type", "")
	var params: Dictionary = effect_data.get("params", {})

	match effect_type:
		"DamageCardEffect":
			var effect_scene = load("res://Scenes/DamageCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.damage_amount = int(params.get("damage", 1))
				var target_name: String = str(params.get("target_name", params.get("target", "Enemy")))
				effect.target_name = target_name.capitalize()
				_apply_params_to_effect(effect, params, ["damage", "target_name", "target"])
				return effect
			return null

		"HealCardEffect":
			var effect_scene = load("res://Scenes/HealCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.heal_amount = int(params.get("heal", 1))
				_apply_params_to_effect(effect, params, ["heal"])
				return effect
			return null

		"DrawCardEffect":
			var effect_scene = load("res://Scenes/DrawCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.draw_amount = int(params.get("count", 1))
				_apply_params_to_effect(effect, params, ["count"])
				return effect
			return null

		"EnergyCardEffect":
			var effect_scene = load("res://Scenes/GainEnergyCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.additional_energy_amount = int(params.get("energy", 1))
				_apply_params_to_effect(effect, params, ["energy"])
				return effect
			return null

		"BuffCardEffect":
			var buff_name: String = params.get("buff", "Shield")
			var stacks: int = max(1, int(params.get("stacks", 1)))
			var target: String = params.get("target", "Player")
			var buff_params: Dictionary = params.duplicate()
			buff_params.erase("buff")
			buff_params.erase("stacks")
			buff_params.erase("target")
			var template_values: Dictionary = params.duplicate(true)
			template_values["buff"] = buff_name
			template_values["stacks"] = stacks
			template_values["target"] = target
			var effects: Array = []
			for _i in range(stacks):
				var buff_effect = _create_buff_effect(buff_name, target, buff_params)
				if buff_effect != null:
					if buff_effect.has_method("set_card_lab_template_values"):
						buff_effect.set_card_lab_template_values(template_values)
					effects.append(buff_effect)
			return effects

		"DebuffCardEffect":
			var debuff_name: String = params.get("debuff", "Vulnerable")
			var debuff_stacks: int = max(1, int(params.get("stacks", 1)))
			var template_values: Dictionary = params.duplicate(true)
			template_values["debuff"] = debuff_name
			template_values["stacks"] = debuff_stacks
			template_values["target"] = "Enemy"
			return _create_debuff_effect(debuff_name, debuff_stacks, template_values)

		"DiscardCardEffect":
			var effect_scene = load("res://Scenes/DiscardCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.max_discard_amount = int(params.get("count", 1))
				_apply_params_to_effect(effect, params, ["count"])
				return effect
			return null

		"SelfDamageCardEffect":
			var effect_scene = load("res://Scenes/ReduceHealthCardEffect.tscn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.reduce_amount = int(params.get("damage", 1))
				effect.target_name = "Player"
				_apply_params_to_effect(effect, params, ["damage"])
				return effect
			return null

		"CreateCardEffect":
			var effect_scene = load("res://Scenes/CreateCardCardEffect.tscn")
			if effect_scene == null:
				push_warning("Could not load CreateCardCardEffect.tscn")
				return null
			var create_effect: CardEffect = effect_scene.instantiate()
			var card_scene_path: String = params.get("card_to_create_scene", params.get("card_scene", ""))
			if card_scene_path.is_empty():
				var legacy_card_name: String = params.get("card_name", "")
				if not legacy_card_name.is_empty():
					card_scene_path = "res://Scenes/%s.tscn" % legacy_card_name
			# Only the game's own cards (by name or their path), never any other file.
			card_scene_path = EffectRegistry.allowed_scene_path("card_to_create_scene", card_scene_path)
			if not card_scene_path.is_empty():
				var card_scene = load(card_scene_path)
				if card_scene is PackedScene:
					create_effect.set("card_to_create_scene", card_scene)
				else:
					push_warning("Could not load card scene: %s" % card_scene_path)
			else:
				push_warning("CreateCardEffect missing card scene path.")
			return create_effect

		"CustomCardEffect":
			# Custom text effects don't have a direct mapping
			# Just ignore for now
			return null

		_:
			push_warning("Unknown effect type: " + effect_type)
			return null

func _create_buff_effect(buff_name: String, target: String = "", buff_params: Dictionary = {}) -> CardEffect:
	# Load the base BuffCardEffect scene
	var buff_card_effect_scene = load("res://Scenes/BuffCardEffect.tscn")
	if buff_card_effect_scene == null:
		push_warning("Could not load BuffCardEffect.tscn")
		return null

	var effect: BuffCardEffect = buff_card_effect_scene.instantiate()

	# Map buff names to their scene paths
	var buff_scene_map = {
		"Blood": "res://Scenes/BloodBuff.tscn",
		# "Buff": "res://Scenes/Buff.tscn",
		"Charge": "res://Scenes/ChargeBuff.tscn",
		"Copy": "res://Scenes/CopyBuff.tscn",
		# "Corrode": "res://Scenes/CorrodeBuff.tscn",
		"Critical": "res://Scenes/CriticalBuff.tscn",
		# "Debuff": "res://Scenes/Debuff.tscn",
		"Discount": "res://Scenes/DiscountBuff.tscn",
		"Doom": "res://Scenes/DoomBuff.tscn",
		"Free": "res://Scenes/FreeBuff.tscn",
		"Lifesteal": "res://Scenes/LifestealBuff.tscn",
		# "ModifyAttackBuff": "res://Scenes/ModifyAttackBuff.tscn",
		"Poison": "res://Scenes/PoisonBuff.tscn",
		"Regen": "res://Scenes/RegenBuff.tscn",
		"Repeat": "res://Scenes/RepeatBuff.tscn",
		# "Retaliate": "res://Scenes/RetaliateBuff.tscn",
		"Return": "res://Scenes/ReturnCardToHandBuff.tscn",
		"Sharp": "res://Scenes/SharpBuff.tscn",
		"Block": "res://Scenes/ShieldBuff.tscn",
		"Trash": "res://Scenes/TrashBuff.tscn",
		"Vulnerable": "res://Scenes/VulnerableDebuff.tscn",
	}

	var buff_scene_path = buff_scene_map.get(buff_name, "res://Scenes/ShieldBuff.tscn")
	effect.set_buff_scene(buff_scene_path)
	var target_from_card_lab: String = "Enemy" if buff_name in ["Corrode", "Vulnerable"] else "Player"
	effect.set_buff_auto_target(target_from_card_lab)
	if not buff_params.is_empty() and effect.has_method("set_buff_params"):
		effect.set_buff_params(buff_params)
	if buff_name == "Sharp":
		effect.defer_add_until_after_card_play = true

	return effect

func _create_debuff_effect(debuff_name: String, stacks: int = 1, template_values: Dictionary = {}):
	var debuff_scene_map = {
		"Vulnerable": "res://Scenes/VulnerableDebuff.tscn",
	}

	var debuff_scene_path = debuff_scene_map.get(debuff_name, "res://Scenes/VulnerableDebuff.tscn")
	var debuff_card_effect_scene = load("res://Scenes/DebuffCardEffect.tscn")
	if debuff_card_effect_scene == null:
		push_warning("Could not load DebuffCardEffect.tscn")
		return null

	stacks = max(1, stacks)
	var effects: Array = []
	for _i in range(stacks):
		var effect = debuff_card_effect_scene.instantiate()
		if effect == null:
			continue
		effect.set_debuff_scene(debuff_scene_path)
		if not template_values.is_empty() and effect.has_method("set_card_lab_template_values"):
			effect.set_card_lab_template_values(template_values)
		effects.append(effect)

	if effects.size() == 1:
		return effects[0]
	return effects

func _resolve_icon_resource_path(icon_value: String) -> String:
	return CardFactory.resolve_icon_path(icon_value)

func _apply_params_to_effect(effect: Object, params: Dictionary, skip_keys: Array = []) -> void:
	if effect == null or params.is_empty():
		return

	var skip_lookup := {}
	for key in skip_keys:
		skip_lookup[key] = true

	var property_lookup := {}
	for property in effect.get_property_list():
		property_lookup[property.name] = true

	for key in params.keys():
		if skip_lookup.has(key):
			continue
		var value = params[key]
		if property_lookup.has(key):
			effect.set(key, value)
		else:
			var setter_name = "set_%s" % key
			if effect.has_method(setter_name):
				effect.call(setter_name, value)
