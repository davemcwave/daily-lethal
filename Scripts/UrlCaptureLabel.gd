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
		# card_path_string = "lunge-card.PNG"
		var card_path_no_png: String = card_path_string.replace(".PNG", "")
		var card_path_two_words = card_path_no_png.split("-")
		var card_first_word = card_path_two_words[0].capitalize()
		var card_second_word = card_path_two_words[1].capitalize()
		var card_scene_path = "res://Scenes/%s%s.scn" % [card_first_word, card_second_word]
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
		var card: Card = load("res://Scenes/Card.scn").instantiate()
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
	# Set basic card properties
	card.card_name = data.get("name", "Custom Card")
	card.energy_cost = int(data.get("energy", 1))
	var description_text: String = data.get("description", "")
	var description_template: String = data.get("description_template", description_text)
	if card.has_method("set_description"):
		card.set_description(description_text)
	else:
		card.card_description = description_text

	# Set card color(s) on the icon panel
	var colors_array: Array = []
	if data.has("colors") and data["colors"] is Array:
		colors_array = data["colors"]
	var primary_color_hex: String = str(colors_array[0]) if colors_array.size() > 0 else data.get("color", "#002A8C")
	var card_color = Color.html(primary_color_hex)

	# Apply color to the card's IconPanel stylebox
	if card.has_node("IconPanel"):
		var icon_panel = card.get_node("IconPanel")
		var style = icon_panel.get_theme_stylebox("panel").duplicate()
		style.bg_color = card_color
		icon_panel.add_theme_stylebox_override("panel", style)
		if card.has_gradient_background():
			var gradient_node = card.get_node("IconPanel/GradientBackground")
			gradient_node.queue_free()
		var gradient_colors := PackedColorArray()
		for color_entry in colors_array:
			if color_entry is String and not String(color_entry).is_empty():
				var gradient_color = Color.html(color_entry)
				gradient_colors.append(gradient_color)
		if gradient_colors.size() >= 2:
			card.add_gradient_background(gradient_colors)

	# Set card icon texture if provided
	var icon_name: String = data.get("icon", "")
	if icon_name != "" and card.has_node("IconPanel/Icon"):
		var icon_path = _resolve_icon_resource_path(icon_name)
		var icon_texture = load(icon_path)
		if icon_texture:
			card.get_node("IconPanel/Icon").set_texture(icon_texture)

	# Add effects based on the effects array
	var effects_data = data.get("effects", [])
	for effect_data in effects_data:
		var effect = _create_effect_from_data(effect_data)
		if effect is Array:
			for single_effect in effect:
				if single_effect == null:
					continue
				card.add_child(single_effect)
				card.card_effects.append(single_effect)
		elif effect != null:
				card.add_child(effect)
				card.card_effects.append(effect)

	if card.has_method("set_description_template"):
		card.set_description_template(description_template)
	else:
		card.set("description_template", description_template)

func _create_effect_from_data(effect_data: Dictionary):
	var effect_type: String = effect_data.get("type", "")
	var params: Dictionary = effect_data.get("params", {})

	match effect_type:
		"DamageCardEffect":
			var effect_scene = load("res://Scenes/DamageCardEffect.scn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.damage_amount = int(params.get("damage", 1))
				var target_name: String = str(params.get("target_name", params.get("target", "Enemy")))
				effect.target_name = target_name.capitalize()
				_apply_params_to_effect(effect, params, ["damage", "target_name", "target"])
				return effect
			return null

		"HealCardEffect":
			var effect_scene = load("res://Scenes/HealCardEffect.scn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.heal_amount = int(params.get("heal", 1))
				_apply_params_to_effect(effect, params, ["heal"])
				return effect
			return null

		"DrawCardEffect":
			var effect_scene = load("res://Scenes/DrawCardEffect.scn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.draw_amount = int(params.get("count", 1))
				_apply_params_to_effect(effect, params, ["count"])
				return effect
			return null

		"EnergyCardEffect":
			var effect_scene = load("res://Scenes/GainEnergyCardEffect.scn")
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
			var effect_scene = load("res://Scenes/DiscardCardEffect.scn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.max_discard_amount = int(params.get("count", 1))
				_apply_params_to_effect(effect, params, ["count"])
				return effect
			return null

		"SelfDamageCardEffect":
			var effect_scene = load("res://Scenes/ReduceHealthCardEffect.scn")
			if effect_scene:
				var effect = effect_scene.instantiate()
				effect.reduce_amount = int(params.get("damage", 1))
				effect.target_name = "Player"
				_apply_params_to_effect(effect, params, ["damage"])
				return effect
			return null

		"CreateCardEffect":
			var effect_scene = load("res://Scenes/CreateCardCardEffect.scn")
			if effect_scene == null:
				push_warning("Could not load CreateCardCardEffect.scn")
				return null
			var create_effect: CardEffect = effect_scene.instantiate()
			var card_scene_path: String = params.get("card_to_create_scene", params.get("card_scene", ""))
			if card_scene_path.is_empty():
				var legacy_card_name: String = params.get("card_name", "")
				if not legacy_card_name.is_empty():
					card_scene_path = "res://Scenes/%s.scn" % legacy_card_name
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
	var buff_card_effect_scene = load("res://Scenes/BuffCardEffect.scn")
	if buff_card_effect_scene == null:
		push_warning("Could not load BuffCardEffect.scn")
		return null

	var effect: BuffCardEffect = buff_card_effect_scene.instantiate()

	# Map buff names to their scene paths
	var buff_scene_map = {
		"Blood": "res://Scenes/BloodBuff.scn",
		# "Buff": "res://Scenes/Buff.scn",
		"Charge": "res://Scenes/ChargeBuff.scn",
		"Copy": "res://Scenes/CopyBuff.scn",
		# "Corrode": "res://Scenes/CorrodeBuff.scn",
		"Critical": "res://Scenes/CriticalBuff.scn",
		# "Debuff": "res://Scenes/Debuff.scn",
		"Discount": "res://Scenes/DiscountBuff.scn",
		"Doom": "res://Scenes/DoomBuff.scn",
		"Free": "res://Scenes/FreeBuff.scn",
		"Lifesteal": "res://Scenes/LifestealBuff.scn",
		# "ModifyAttackBuff": "res://Scenes/ModifyAttackBuff.scn",
		"Poison": "res://Scenes/PoisonBuff.scn",
		"Regen": "res://Scenes/RegenBuff.scn",
		"Repeat": "res://Scenes/RepeatBuff.scn",
		# "Retaliate": "res://Scenes/RetaliateBuff.scn",
		"Return": "res://Scenes/ReturnCardToHandBuff.scn",
		"Sharp": "res://Scenes/SharpBuff.scn",
		"Block": "res://Scenes/ShieldBuff.scn",
		"Trash": "res://Scenes/TrashBuff.scn",
		"Vulnerable": "res://Scenes/VulnerableDebuff.scn",
	}

	var buff_scene_path = buff_scene_map.get(buff_name, "res://Scenes/ShieldBuff.scn")
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
		"Vulnerable": "res://Scenes/VulnerableDebuff.scn",
	}

	var debuff_scene_path = debuff_scene_map.get(debuff_name, "res://Scenes/VulnerableDebuff.scn")
	var debuff_card_effect_scene = load("res://Scenes/DebuffCardEffect.scn")
	if debuff_card_effect_scene == null:
		push_warning("Could not load DebuffCardEffect.scn")
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
	if icon_value.begins_with("res://"):
		return icon_value
	if icon_value.begins_with("Assets/"):
		return "res://%s" % icon_value
	if icon_value.begins_with("../"):
		return "res://%s" % icon_value.substr(3, icon_value.length() - 3)
	if icon_value.begins_with("./"):
		return "res://%s" % icon_value.substr(2, icon_value.length() - 2)
	var normalized := icon_value
	var lower := normalized.to_lower()
	if not (lower.ends_with(".png") or lower.ends_with(".svg") or lower.ends_with(".jpg") \
		or lower.ends_with(".jpeg") or lower.ends_with(".webp") or lower.ends_with(".gif")):
		normalized += ".png"
	return "res://Assets/Textures/%s" % normalized

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
