extends SceneTree
## Every input on every Card Lab effect shows the effect's real value, and changing
## it changes the effect.
##
##   godot --headless --path . --script res://Tests/card_lab_input_tests.gd
##
## For each effect the Card Lab offers (with "More settings" open), and for the Buff
## effect with every buff chosen (its own settings: Sharp Count, Heal Amount, ...):
##   1. the value the Card Lab shows == the value on the effect a card is built with
##      (a setting that defaults to false is unticked AND false on the effect);
##   2. changing it through the Card Lab's own control (typing, ticking, picking)
##      gives the built effect exactly that value.

const LAB_SCENE := "res://Scenes/Builder/CardBuilder.tscn"

var failures: Array[String] = []
var checks := 0
var lab


func _init() -> void:
	lab = load(LAB_SCENE).instantiate()
	root.add_child(lab)
	await process_frame
	lab.show_advanced = true  # every setting, not just the main ones

	var offered: Array = EffectRegistry.get_card_lab_effect_ids()
	var inputs := 0
	for id in offered:
		inputs += await _test_effect(id, {"type": id}, "")
	print("effect inputs checked: %d (on %d effects)" % [inputs, offered.size()])

	var buff_inputs := 0
	var buffs: Array = EffectRegistry.get_offered_buff_choices()
	for buff: Dictionary in buffs:
		buff_inputs += await _test_effect("Buff", {"type": "Buff", "params": {"buff_scene": buff["id"]}}, buff["id"])
	print("buff settings checked: %d (on %d buffs)" % [buff_inputs, buffs.size()])

	await _test_new_buff_effect_defers()
	await _test_buff_targets()
	await _test_nested_effects()
	await _test_several_cards()
	await _test_hand_order_and_icons()
	await _test_import_adds()

	print("")
	print("==== CARD LAB INPUT TEST SUMMARY ====")
	for failure in failures:
		print("FAIL  " + failure)
	print("checks %d, failed %d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


## Loads one effect into the Card Lab and checks each of its inputs (and, with a
## buff chosen, the buff's own settings). Returns how many inputs it checked.
func _test_effect(id: String, effect_definition: Dictionary, buff_id: String) -> int:
	var checked := 0
	var where := id + (" (" + buff_id + ")" if not buff_id.is_empty() else "")
	var params: Array = [] if not buff_id.is_empty() else EffectRegistry.get_params(id)
	if not buff_id.is_empty():
		for info: Dictionary in EffectRegistry.get_scene_params(EffectRegistry.allowed_scene_path("buff_scene", buff_id)):
			info["buff_setting"] = true
			params.append(info)
	for info: Dictionary in params:
		if info["kind"] in [EffectRegistry.KIND_EFFECTS, EffectRegistry.KIND_DICT] or info["name"] in lab.HIDDEN_PARAMS:
			continue  # nested effects: their own list (nested tests below); buff_params: per buff; hidden: set by the Card Lab
		await _load(effect_definition)
		var label: String = ("  " if info.get("buff_setting", false) else "") + lab._setting_label(info["name"])
		var editor := _find_editor(label)
		_check(editor != null, "%s: no input for '%s'" % [where, info["name"]])
		if editor == null:
			continue
		checked += 1
		var name_text := "%s.%s" % [where, info["name"]]

		# 1. Shows the real value.
		var actual = _built_value(info)
		var shown = _shown_value(editor, info)
		_check(_same(shown, _expected_shown(actual, info)), "%s shows %s but the effect has %s" % [name_text, shown, actual])

		# 2. Changing it changes the effect.
		var wanted = await _change(editor, info, actual)
		if wanted == null:
			continue
		var after = _built_value(info)
		_check(_same(_expected_shown(after, info), wanted), "%s: set to %s in the Card Lab, but the effect has %s" % [name_text, wanted, after])
	return checked


func _load(effect_definition: Dictionary) -> void:
	lab.definition = {"format": 1, "name": "Input test", "energy": 1, "description": "x", "effects": [effect_definition.duplicate(true)]}
	lab._open_effect = 0
	lab._load_definition_into_ui()
	await process_frame
	await process_frame


## The input control on the row labeled `label` in the open effect panel.
func _find_editor(label: String) -> Control:
	for row in _all(lab.effects_box):
		if row is HBoxContainer and row.get_child_count() >= 2 and row.get_child(0) is Label \
				and row.get_child(0).text == label and not row.is_queued_for_deletion():
			return row.get_child(1)
	return null

func _all(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		found.append(child)
		found.append_array(_all(child))
	return found

func _first(editor: Control, type_name: String) -> Control:
	if editor.is_class(type_name):
		return editor
	for child in _all(editor):
		if child.is_class(type_name):
			return child
	return null


## The setting's value on the effect a card is actually built with (for a buff
## setting: on the buff, after the effect applies its settings to it).
func _built_value(info: Dictionary):
	var card: Card = CardFactory.create_card(lab.definition)
	var effect: CardEffect = card.card_effects[0]
	var value
	if info.get("buff_setting", false):
		var buff: Buff = load(EffectRegistry.allowed_scene_path("buff_scene", str(effect.buff_scene))).instantiate()
		effect._apply_params_to_buff(buff, effect.buff_params)
		value = buff.get(info["name"])
		buff.free()
	else:
		value = effect.get(info["name"])
	card.free()
	return value


## What the Card Lab should show for a value.
func _expected_shown(value, info: Dictionary):
	match info["kind"]:
		EffectRegistry.KIND_ENUM:
			var options: Array = info.get("options", [])
			return options[int(value)] if (value is int or value is float) and int(value) < options.size() else str(value)
		EffectRegistry.KIND_RESOURCE:
			var path: String = value.resource_path if value is Resource else str(value if value != null else "")
			var name := EffectRegistry.scene_name(path)
			return "Choose..." if name.is_empty() else name.capitalize()
		EffectRegistry.KIND_RESOURCES:
			var names: Array = []
			for item in value:
				names.append(EffectRegistry.scene_name(item.resource_path).capitalize())
			return names
		EffectRegistry.KIND_INT:
			return int(value)
		EffectRegistry.KIND_FLOAT:
			return snappedf(float(value), 0.001)
		EffectRegistry.KIND_COLOR:
			return (value as Color).to_html(true)
	return value


func _shown_value(editor: Control, info: Dictionary):
	match info["kind"]:
		EffectRegistry.KIND_INT:
			return _first(editor, "LineEdit").text.to_int()
		EffectRegistry.KIND_FLOAT:
			return snappedf(_first(editor, "LineEdit").text.to_float(), 0.001)
		EffectRegistry.KIND_BOOL:
			return _first(editor, "CheckBox").button_pressed
		EffectRegistry.KIND_STRING:
			return _first(editor, "LineEdit").text
		EffectRegistry.KIND_ENUM, EffectRegistry.KIND_RESOURCE:
			var option: OptionButton = _first(editor, "OptionButton")
			return option.get_item_text(option.selected)
		EffectRegistry.KIND_RESOURCES:
			var names: Array = []
			for child in _all(editor):
				if child is Button and not (child is OptionButton) and child.text.ends_with("×"):
					names.append(child.text.trim_suffix("×").strip_edges())
			return names
		EffectRegistry.KIND_COLOR:
			return _first(editor, "ColorPickerButton").color.to_html(true)
	return null


## Changes the input the way a player would; returns the value it should now show
## (and the effect should have), or null when there's nothing else to pick.
func _change(editor: Control, info: Dictionary, current):
	match info["kind"]:
		EffectRegistry.KIND_INT, EffectRegistry.KIND_FLOAT:
			var edit: LineEdit = _first(editor, "LineEdit")
			var next := int(current) + 2
			edit.text = str(next)
			edit.text_changed.emit(edit.text)
			return next if info["kind"] == EffectRegistry.KIND_INT else snappedf(float(next), 0.001)
		EffectRegistry.KIND_BOOL:
			var check: CheckBox = _first(editor, "CheckBox")
			check.button_pressed = not check.button_pressed  # emits toggled
			return check.button_pressed
		EffectRegistry.KIND_STRING:
			var edit: LineEdit = _first(editor, "LineEdit")
			edit.text = "Changed"
			edit.text_changed.emit(edit.text)
			return "Changed"
		EffectRegistry.KIND_ENUM, EffectRegistry.KIND_RESOURCE:
			var option: OptionButton = _first(editor, "OptionButton")
			var start := 1 if info["kind"] == EffectRegistry.KIND_RESOURCE else 0  # skip "Choose..."
			for i in range(start, option.item_count):
				if i != option.selected:
					var text := option.get_item_text(i)  # read first: picking rebuilds the panel
					option.select(i)
					option.item_selected.emit(i)
					await process_frame
					return text
			return null
		EffectRegistry.KIND_RESOURCES:
			var shown: Array = _shown_value(editor, info)
			var picker: OptionButton = _first(editor, "OptionButton")
			picker.select(0)
			shown.append(picker.get_item_text(0))  # read first: adding rebuilds the panel
			for child in _all(editor):
				if child is Button and child.text == "Add":
					child.pressed.emit()
			await process_frame
			return shown
		EffectRegistry.KIND_COLOR:
			var picker: ColorPickerButton = _first(editor, "ColorPickerButton")
			picker.color = Color(0.2, 0.4, 0.6, 1.0)
			picker.color_changed.emit(picker.color)
			return picker.color.to_html(true)
	return null


func _same(a, b) -> bool:
	if a is float or b is float:
		return absf(float(a) - float(b)) < 0.001
	return str(a) == str(b)


## A Buff effect added from the Card Lab adds its buff after the card's play (else
## Sharp is used up by the card that gives it): the box shows ticked, and is.
func _test_new_buff_effect_defers() -> void:
	lab.definition = {"format": 1, "name": "x", "energy": 1, "description": "x", "effects": []}
	lab._load_definition_into_ui()
	for i in lab.effect_picker.item_count:
		if lab.effect_picker.get_item_metadata(i) == "Buff":
			lab.effect_picker.select(i)
	lab._on_add_effect()
	await process_frame
	await process_frame
	var info := {"name": "defer_add_until_after_card_play", "kind": EffectRegistry.KIND_BOOL}
	var editor := _find_editor(lab._setting_label(info["name"]))
	_check(editor != null and _shown_value(editor, info) == true, "new Buff effect: 'Defer Add Until After Card Play' isn't ticked")
	_check(_built_value(info) == true, "new Buff effect: the effect doesn't defer")


## Effects inside effects are built in the Effects tab: a Condition's "Then" (one
## effect) and a choice effect's "Choices" (any number), each edited, moved and
## removed with the same panel as the card's own effects.
func _test_nested_effects() -> void:
	# Condition -> Then: Damage, then change the inner Damage's amount.
	await _load({"type": "Condition"})
	_check(_labels("Then").size() == 1, "Condition: no 'Then' list")
	await _add_nested("Damage", 0)
	var effect: Dictionary = lab.definition["effects"][0]
	_check(effect.get("children", []).size() == 1 and effect["children"][0]["type"] == "Damage",
		"Condition: Then didn't get the Damage: %s" % JSON.stringify(effect))
	_check(_buttons("Add").is_empty(), "Condition: still offers to add a second Then effect (only the first runs)")
	var amount := _find_editor(lab._setting_label("damage_amount"))
	_check(amount != null, "Condition: the new Then effect isn't open for editing")
	if amount != null:
		var edit: LineEdit = _first(amount, "LineEdit")
		edit.text = "7"
		edit.text_changed.emit("7")
		await process_frame
		var card: Card = CardFactory.create_card(lab.definition)
		var condition: CardEffect = card.card_effects[0]
		var inner = condition.get_child(0) if condition.get_child_count() > 0 else null
		_check(inner is CardEffect and inner.get("damage_amount") == 7,
			"Condition: Then Damage set to 7 in the Card Lab, built effect has %s" % (inner.get("damage_amount") if inner != null else "no inner effect"))
		card.free()

	# Player Choose Effect -> Choices: add two, move the second up, remove one.
	await _load({"type": "PlayerChooseEffect"})
	_check(_labels("Choices").size() == 1, "Player Choose Effect: no 'Choices' list")
	await _add_nested("Damage", 0)
	await _add_nested("Heal", 0)
	var choices: Array = lab.definition["effects"][0].get("params", {}).get("card_effects_to_choose_from", [])
	_check(choices.map(func(e): return e["type"]) == ["Damage", "Heal"], "Choices after adding: %s" % JSON.stringify(choices))
	var built: Card = CardFactory.create_card(lab.definition)
	_check(built.card_effects[0].card_effects_to_choose_from.size() == 2, "Choices: built effect has %d choices" % built.card_effects[0].card_effects_to_choose_from.size())
	built.free()
	var up := _buttons("Up")
	_check(up.size() == 1, "Choices: %d Up buttons, want 1 (on the second choice)" % up.size())
	if up.size() == 1:
		up[0].pressed.emit()
		await process_frame
		choices = lab.definition["effects"][0]["params"]["card_effects_to_choose_from"]
		_check(choices.map(func(e): return e["type"]) == ["Heal", "Damage"], "Choices after Up: %s" % JSON.stringify(choices))
	var removes := _buttons("×")  # the card's own effect first, then each choice
	if removes.size() == 3:
		removes[1].pressed.emit()
		await process_frame
		choices = lab.definition["effects"][0]["params"]["card_effects_to_choose_from"]
		_check(choices.map(func(e): return e["type"]) == ["Damage"], "Choices after removing the first: %s" % JSON.stringify(choices))
	else:
		_check(false, "Choices: %d remove buttons, want 3" % removes.size())

## Several custom cards: "+ Card" adds one, the chips switch between them, each
## keeps its own effects, the Test hand adds cards on the end and takes them
## out, and the share code keeps the hand in order.
func _test_several_cards() -> void:
	lab.cards = [{"format": 1, "name": "First", "energy": 1, "description": "x", "effects": [{"type": "Damage"}]}]
	lab.current_card = 0
	lab.definition = lab.cards[0]
	lab.hand = [0, 0, "res://Scenes/SlashCard.tscn"]
	lab._load_definition_into_ui()
	lab._refresh()
	await process_frame
	_check(_slot_names() == ["First", "First", "Slash"], "hand slots: %s, want First, First, Slash" % [_slot_names()])
	var add := _all(lab.card_tabs).filter(func(n): return n is Button and n.text == "+ Card")
	_check(add.size() == 1, "several cards: no '+ Card' button")
	if add.is_empty():
		return
	add[0].pressed.emit()
	await process_frame
	_check(lab.cards.size() == 2 and lab.current_card == 1, "several cards: '+ Card' didn't add and open a second card")
	lab.definition["name"] = "Second"
	lab.definition["effects"] = [{"type": "Heal"}]
	lab._refresh()
	await process_frame
	_check(_slot_names() == ["First", "First", "Slash", "Second"], "hand slots after adding a card: %s" % [_slot_names()])
	# "+" offers your cards, then the built-in ones; what you pick goes on the end.
	var plus := _all(lab.hand_slots).filter(func(n): return n is Button and n.text.begins_with("+"))
	_check(plus.size() == 1, "hand: no '+' slot")
	if plus.is_empty():
		return
	plus[0].pressed.emit()
	await process_frame
	var ids := {}
	for i in lab.hand_picker.item_count:
		ids[lab.hand_picker.get_item_text(i)] = lab.hand_picker.get_item_id(i)
	lab.hand_picker.hide()
	_check(ids.has("First") and ids.has("Echo"), "hand '+' doesn't offer First and Echo")
	if not (ids.has("First") and ids.has("Echo")):
		return
	lab.hand_picker.id_pressed.emit(ids["Echo"])
	lab.hand_picker.id_pressed.emit(ids["First"])
	await process_frame
	_check(_slot_names() == ["First", "First", "Slash", "Second", "Echo", "First"],
		"hand after adding Echo then First: %s" % [_slot_names()])
	# "×" takes that card out; your cards keep at least one.
	var slash_slot = _all(lab.hand_slots).filter(func(n): return n.has_meta("card_name") and n.get_meta("card_name") == "Slash" and not n.is_queued_for_deletion())
	var removes = slash_slot[0].get_children().filter(func(n): return n is Button and n.text == "×") if not slash_slot.is_empty() else []
	_check(removes.size() == 1, "hand: no × on the Slash slot")
	if not removes.is_empty():
		removes[0].pressed.emit()
		await process_frame
	_check(_slot_names() == ["First", "First", "Second", "Echo", "First"], "hand after removing Slash: %s" % [_slot_names()])
	lab._remove_from_hand(2)  # Second's only copy stays
	await process_frame
	_check(_slot_names() == ["First", "First", "Second", "Echo", "First"], "hand: removed the last copy of Second: %s" % [_slot_names()])
	var first_chip := _all(lab.card_tabs).filter(func(n): return n is Button and n.text == "First")
	_check(first_chip.size() == 1, "several cards: no chip for the first card")
	if first_chip.is_empty():
		return
	first_chip[0].pressed.emit()
	await process_frame
	_check(lab.current_card == 0 and lab.definition["name"] == "First",
		"several cards: switching back shows %s" % [lab.definition.get("name")])
	_check(lab.cards[1]["name"] == "Second" and lab.cards[1]["effects"][0]["type"] == "Heal", "several cards: the second card lost its edits")
	var code := ShareCode.decode(ShareCode.encode(lab.cards, lab._try_settings()))
	_check(not code.has("error") and code["cards"].size() == 2 and code["puzzle"]["card_copies"] == [3, 1],
		"several cards: share code holds %s" % JSON.stringify(code))
	var shared_hand := ShareCode.hand_from(code.get("puzzle", {}), 2)
	_check(shared_hand == [0, 0, 1, "res://Scenes/EchoCard.tscn", 0], "share code hand order: %s" % [shared_hand])

## Dragging a card in the Test hand moves it; the icon picker sets the card's
## icon; a long name and description shrink to fit the card.
func _test_hand_order_and_icons() -> void:
	lab.cards = [{"format": 1, "name": "First", "energy": 1, "description": "x", "effects": [{"type": "Damage"}]}]
	lab.current_card = 0
	lab.definition = lab.cards[0]
	lab.hand = [0, "res://Scenes/SlashCard.tscn", "res://Scenes/EchoCard.tscn"]
	lab._load_definition_into_ui()
	lab._refresh()
	await process_frame
	lab._move_in_hand(2, 0)  # Echo dropped on the left half of the first card
	_check(_slot_names() == ["Echo", "First", "Slash"], "reorder to the front: %s" % [_slot_names()])
	lab._move_in_hand(0, lab.hand.size())  # dropped on "+"
	_check(_slot_names() == ["First", "Slash", "Echo"], "reorder to the end: %s" % [_slot_names()])
	lab._move_in_hand(0, 2)  # dropped on the left half of Echo
	_check(_slot_names() == ["Slash", "First", "Echo"], "reorder into the middle: %s" % [_slot_names()])

	lab._open_icon_picker()
	await process_frame
	var picked: Dictionary = lab._icons()[-1]
	var tiles := _all(lab.icon_layer).filter(func(n): return n is Button and n.tooltip_text == picked["name"])
	_check(tiles.size() == 1, "icon picker: no tile for %s" % picked["name"])
	if not tiles.is_empty():
		tiles[0].pressed.emit()
		await process_frame
	_check(CardFactory.resolve_icon_path(str(lab.definition.get("icon"))) == picked["path"], "icon picker: card icon is %s, want %s" % [lab.definition.get("icon"), picked["path"]])
	_check(lab.preview_card.get_icon_texture().resource_path == picked["path"], "icon picker: preview didn't change")
	_check(lab.icon_layer == null, "icon picker: still open after picking")
	_check(lab._icons().size() > 20 and not lab._icons().any(func(icon): return icon["name"] == "bg-evil"),
		"icon picker: offers %d icons, want only the built-in cards' icons" % lab._icons().size())

	lab.definition["name"] = "Supermassive Fusion Hammer"
	lab.definition["description"] = "Deal 4 damage. If you have 3 or more energy, deal 4 more damage and draw a card. Gain 1 energy."
	lab.definition.erase("description_template")
	lab._load_definition_into_ui()
	lab._refresh()
	for i in 3:
		await process_frame
	for path in ["TitlePanel/Title", "DescriptionPanel/Title"]:
		var label: RichTextLabel = lab.preview.get_node(path)
		var room := TextFit._box_height(label)
		var used := TextFit._text_height(label.get_theme_font("normal_font"), label.get_parsed_text(), label.size.x - 4.0, label.get_theme_font_size("normal_font_size"))
		# Headless Godot measures text a little taller than a real window does, so
		# here it may bottom out at the smallest size; in a window it fits.
		var shrunk: int = label.get_theme_font_size("normal_font_size")
		_check(shrunk < 12 and (used <= room or shrunk == 7),
			"long card: %s is %.0f tall in %.0f at size %d (width %.0f, text %s)" % [path, used, room, label.get_theme_font_size("normal_font_size"), label.size.x, label.get_parsed_text()])

## "Add to my cards" keeps your cards and Test hand settings and puts the shared
## cards after them, each in the hand as often as the code has it.
func _test_import_adds() -> void:
	lab.cards = [{"format": 1, "name": "Mine", "energy": 1, "description": "x", "effects": [{"type": "Damage"}]}]
	lab.current_card = 0
	lab.definition = lab.cards[0]
	lab.hand = [0, "res://Scenes/SlashCard.tscn"]
	lab._load_definition_into_ui()
	lab._refresh()
	lab.test_hp.text = "33"
	var theirs := {"format": 1, "name": "Theirs", "energy": 0, "description": "y", "effects": [{"type": "Heal"}]}
	var code := ShareCode.encode([theirs], {"hp": 5, "card_copies": [2], "other_cards": ["Echo"]})
	lab._open_import()
	lab.import_edit.text = code
	lab._on_import_add()
	await process_frame
	_check(lab.cards.map(func(c): return c["name"]) == ["Mine", "Theirs"], "import add: cards are %s" % [lab.cards.map(func(c): return c["name"])])
	_check(_slot_names() == ["Mine", "Slash", "Theirs", "Theirs"], "import add: hand is %s" % [_slot_names()])
	_check(lab.test_hp.text == "33", "import add: changed your HP setting to %s" % lab.test_hp.text)
	_check(lab.current_card == 1 and lab.import_layer == null, "import add: didn't open the added card and close the box")
	# Right-click Delete on a card that isn't open: it goes, with its hand copies;
	# the open card stays open.
	lab._open_card_menu(0)
	_check(not lab.card_menu.is_item_disabled(0), "card menu: Delete is off with two cards")
	lab.card_menu.hide()
	lab.card_menu.id_pressed.emit(0)
	await process_frame
	_check(lab.cards.map(func(c): return c["name"]) == ["Theirs"] and lab.definition["name"] == "Theirs",
		"card menu: after deleting Mine, cards are %s, open is %s" % [lab.cards.map(func(c): return c["name"]), lab.definition.get("name")])
	_check(_slot_names() == ["Slash", "Theirs", "Theirs"], "card menu: hand after delete is %s" % [_slot_names()])
	lab._open_card_menu(0)
	_check(lab.card_menu.is_item_disabled(0), "card menu: can delete your only card")
	lab.card_menu.hide()

## The names on the Test hand's slots, in order ("+" left out).
func _slot_names() -> Array:
	var names: Array = []
	for slot in lab.hand_slots.get_children():
		if slot.is_queued_for_deletion() or not slot.has_meta("card_name"):
			continue
		names.append(slot.get_meta("card_name"))
	return names

## Picks `type` in the index-th nested Add row and presses Add.
func _add_nested(type: String, index: int) -> void:
	var adds := _buttons("Add")
	if adds.size() <= index:
		_check(false, "no nested Add button to add %s" % type)
		return
	var picker: OptionButton = adds[index].get_parent().get_child(0)
	var found := false
	for i in picker.item_count:
		if picker.get_item_metadata(i) == type:
			picker.select(i)
			found = true
	_check(found, "nested Add doesn't offer %s" % type)
	adds[index].pressed.emit()
	await process_frame
	await process_frame

func _buttons(text: String) -> Array:
	return _all(lab.effects_box).filter(func(n): return n is Button and not n is OptionButton and n.text == text and not n.is_queued_for_deletion())

func _labels(text: String) -> Array:
	return _all(lab.effects_box).filter(func(n): return n is Label and n.text == text and not n.is_queued_for_deletion())


## Buffs go on the player, except Corrode, which (like the Corrode card) goes on the
## enemy; the Card Lab sets that when the buff is picked. Enemy-only abilities and
## the ModifyAttack interface aren't offered.
func _test_buff_targets() -> void:
	var offered: Array = EffectRegistry.get_offered_buff_choices().map(func(c): return c["id"])
	for hidden in ["ModifyAttack", "Doom", "Retaliate"]:
		_check(not hidden in offered, "buff list offers %s" % hidden)
	_check("Corrode" in offered and "Sharp" in offered, "buff list misses Corrode or Sharp: %s" % [offered])
	for pick in ["Corrode", "Sharp", "Corrode", "Regen"]:
		await _load({"type": "Buff"})
		var editor := _find_editor(lab._setting_label("buff_scene"))
		var option: OptionButton = _first(editor, "OptionButton")
		for i in option.item_count:
			if option.get_item_text(i) == pick.capitalize():
				option.select(i)
				option.item_selected.emit(i)
		await process_frame
		var want := "Enemy" if pick == "Corrode" else "Player"
		var target = _built_value({"name": "buff_auto_target", "kind": EffectRegistry.KIND_ENUM})
		_check(str(target) == want, "picking %s: the buff goes on %s, want %s" % [pick, target, want])
