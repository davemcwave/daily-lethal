extends SceneTree
## Content tests: effects, cards and the Card Lab as data.
##
##   godot --headless --path . --script res://Tests/content_tests.gd
##   godot --headless --path . --script res://Tests/content_tests.gd -- --capture-card-lab
##
## Checks:
##  1. Every effect scene is in the registry and can be built from its defaults.
##  2. Every built-in card survives card -> data -> card with identical data.
##  3. Card Lab custom cards (Tests/card_lab_samples.json) build exactly as
##     recorded in Tests/card_lab_golden.json (--capture-card-lab re-records it).
##  4. Card Lab cards can use registry effects the old Card Lab didn't support.
## Exit code 0 = all passed.

const SAMPLES_PATH := "res://Tests/card_lab_samples.json"
const GOLDEN_PATH := "res://Tests/card_lab_golden.json"
const CARD_LAB_SCRIPT := "res://Scripts/UrlCaptureLabel.gd"

var failures: Array[String] = []
var checks := 0
const GRADIENT_LAYOUT_EXCEPTIONS := ["DrainCard.tscn"]

func _init() -> void:
	if "--capture-card-lab" in OS.get_cmdline_user_args():
		_capture_card_lab_golden()
		quit()
		return
	_test_registry()
	_test_builtin_round_trip()
	_test_card_lab_golden()
	_test_card_lab_registry_effects()
	_test_font_has_every_character()
	_test_share_codes()
	_test_short_descriptions()
	print("")
	print("==== CONTENT TEST SUMMARY ====")
	for failure in failures:
		print("FAIL  " + failure)
	print("checks %d, failed %d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

## Web builds have no system fonts to fall back on, so a character the game font
## lacks (an arrow, a check mark) shows as a box with its code in it. Checks every
## string in Scripts/ and every text in Scenes/ (console prints and the share text,
## which goes to the clipboard, are left out).
func _test_font_has_every_character() -> void:
	var font: Font = load("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
	var literal := RegEx.create_from_string("\"(?:[^\"\\\\]|\\\\.)*\"")
	var missing := {}
	for path in _files_under("res://Scripts", ".gd") + _files_under("res://Scenes", ".tscn"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#") or line.contains("print(") or line.begins_with("var share_text_template"):
				continue
			if path.ends_with(".tscn") and not line.begins_with("text = "):
				continue
			for found in literal.search_all(line):
				for character in found.get_string():
					var code := character.unicode_at(0)
					if code > 127 and not font.has_char(code):
						missing["%s (U+%X) in %s:%d" % [character, code, path.trim_prefix("res://"), i + 1]] = true
	for where in missing:
		_check(false, "the game font can't draw " + where)
	_check(true, "font coverage")

func _files_under(dir: String, extension: String) -> Array[String]:
	var paths: Array[String] = []
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(extension):
			paths.append(dir.path_join(name))
	for sub in DirAccess.get_directories_at(dir):
		if sub != "Nightmare":
			paths.append_array(_files_under(dir.path_join(sub), extension))
	return paths

## Card Lab share codes: what goes in comes back out, and codes from other
## people can't name files or break the Card Lab.
## Every effect has words for the Pick 1 effect buttons, even ones made in the
## Card Lab with no short description of their own.
func _test_short_descriptions() -> void:
	for id in EffectRegistry.get_effect_ids():
		var effect := EffectRegistry.create_effect({"type": id})
		if effect == null:
			continue
		var text := effect.get_effect_short_description()
		_check(not text.strip_edges().is_empty() and not text.contains("{") and not text.contains("uid") and not text.contains("::"),
			"short description of %s: '%s'" % [id, text])
		effect.free()
	var burn := EffectRegistry.create_effect({"type": "Debuff", "params": {"debuff_scene": "Burn", "stacks": 3}})
	_check(burn.get_effect_short_description() == "Inflict 3 Burn", "short description of Burn 3: '%s'" % burn.get_effect_short_description())
	burn.free()
	var sharp := EffectRegistry.create_effect({"type": "Buff", "params": {"buff_scene": "Sharp", "buff_params": {"sharp_count": 2}}})
	_check(sharp.get_effect_short_description() == "Gain Sharp 2", "short description of Sharp 2: '%s'" % sharp.get_effect_short_description())
	sharp.free()

func _test_share_codes() -> void:
	var card := {"name": "Shared", "energy": 2, "description": "Deal 4 damage.",
		"effects": [{"type": "Damage", "params": {"damage_amount": 4}}]}
	var puzzle := {"hp": 7, "energy": 3, "enemy_hp": 30, "copies": 2,
		"other_cards": ["res://Scenes/SlashCard.tscn", "Echo"]}
	var code := ShareCode.encode(card, puzzle)
	_check(code.begins_with(ShareCode.PREFIX), "share code: no prefix: " + code.left(20))
	_check(code.length() < 200, "share code: %d characters for a small card" % code.length())
	var back := ShareCode.decode(code)
	_check(not back.has("error"), "share code: own code refused: %s" % back.get("error", ""))
	if not back.has("error"):
		_check(_json(back["card"]) == _json(JSON.parse_string(JSON.stringify(card))), "share code: card changed: %s" % _json(back["card"]))  # JSON reads numbers as floats
		var got: Dictionary = back["puzzle"]
		_check(got["hp"] == 7 and got["energy"] == 3 and got["enemy_hp"] == 30 and got["copies"] == 2,
			"share code: settings changed: %s" % _json(got))
		_check(_json(got["other_cards"]) == _json(["res://Scenes/SlashCard.tscn", "res://Scenes/EchoCard.tscn"]),
			"share code: other cards: %s" % _json(got["other_cards"]))
		# The card it carries builds like any card.
		var built := CardFactory.create_card(back["card"])
		_check(built.card_name == "Shared" and built.energy_cost == 2, "share code: card doesn't build")
		built.free()
	# Pasted from chat with line breaks and spaces.
	var spaced := code.left(30) + "
 " + code.substr(30)
	_check(not ShareCode.decode(spaced).has("error"), "share code: line breaks in a pasted code")
	# Not codes / damaged codes.
	for bad in ["", "hello", ShareCode.PREFIX, ShareCode.PREFIX + "!!!!", code.left(code.length() / 2)]:
		_check(ShareCode.decode(bad).has("error"), "share code: accepted junk: '%s'" % bad.left(30))
	# Someone else's code: file paths and unknown cards left out, numbers clamped.
	var hostile := _raw_code({"c": {"n": "Shared"}, "p": [-5, 1e9, "x", 500,
		"res://Scripts/Card.gd", "user://evil.tscn", "Slash", "NotACard"]})
	var safe := ShareCode.decode(hostile)
	_check(not safe.has("error"), "share code: hostile code refused outright: %s" % safe.get("error", ""))
	if not safe.has("error"):
		var p2: Dictionary = safe["puzzle"]
		_check(_json(p2["other_cards"]) == _json(["res://Scenes/SlashCard.tscn"]), "share code: kept a bad card: %s" % _json(p2["other_cards"]))
		_check(p2["hp"] == 1 and p2["energy"] == ShareCode.MAX_NUMBER and p2["enemy_hp"] == 20 and p2["copies"] == ShareCode.MAX_COPIES,
			"share code: numbers not clamped: %s" % _json(p2))
		_check(safe.get("unknown_cards", []).size() == 3, "share code: unknown cards not reported: %s" % _json(safe.get("unknown_cards", [])))
	_check(ShareCode.decode(_raw_code({"c": "nope"})).has("error"), "share code: accepted a code with no card")
	# Deeply nested junk effects don't recurse forever.
	var deep: Array = ["Damage"]
	for i in 100:
		deep = ["Condition", {}, [deep]]
	_check(not ShareCode.decode(_raw_code({"c": {"n": "Deep", "f": [deep]}, "p": []})).has("error"), "share code: deep nesting refused outright")

	# Every built-in card survives a code: same card after card -> code -> card.
	for path in _builtin_card_paths():
		var original = load(path).instantiate()
		if not (original is Card):  # e.g. a scene that only ends in "Card"
			original.free()
			continue
		var definition := CardFactory.describe_card(original)
		original.free()
		var decoded := ShareCode.decode(ShareCode.encode(definition, {}))
		if decoded.has("error"):
			_check(false, "share code %s: %s" % [path.get_file(), decoded["error"]])
			continue
		var rebuilt := CardFactory.create_card(decoded["card"])
		var again := CardFactory.describe_card(rebuilt)
		rebuilt.free()
		_check(_json(again) == _json(definition), "share code %s: card differs
      original: %s
      from code: %s" % [path.get_file(), _json(definition), _json(again)])

	# Several custom cards, each with its own copies.
	var second := {"name": "Second", "energy": 0, "description": "Draw 1.", "effects": [{"type": "Draw"}]}
	var multi := ShareCode.decode(ShareCode.encode([card, second], {"hp": 5, "card_copies": [2, 3], "other_cards": ["Slash"]}))
	_check(not multi.has("error") and multi["cards"].size() == 2 and multi["cards"][1]["name"] == "Second"
		and multi["puzzle"]["card_copies"] == [2, 3] and multi["puzzle"]["hp"] == 5,
		"share code: two cards: %s" % _json(multi))
	# The hand's order: kept when it isn't the usual one, a bad order is ignored.
	var mixed := {"card_copies": [2, 1], "other_cards": ["Slash", "Echo"], "order": [-2, 0, 1, -1, 0]}
	var ordered := ShareCode.decode(ShareCode.encode([card, second], mixed))
	var ordered_hand := ShareCode.hand_from(ordered.get("puzzle", {}), 2)
	_check(ordered_hand == ["res://Scenes/EchoCard.tscn", 0, 1, "res://Scenes/SlashCard.tscn", 0],
		"share code: hand order: %s" % _json(ordered_hand))
	_check(not multi["puzzle"].has("order"), "share code: stored the usual order: %s" % _json(multi["puzzle"]))
	var bad_order := ShareCode.hand_from({"card_copies": [2], "other_cards": ["Slash"], "order": [0, 7, -1]}, 1)
	_check(bad_order == [0, 0, "Slash"], "share code: bad order not ignored: %s" % _json(bad_order))
	# A one-card code shared before several cards were possible still imports.
	var ember := ShareCode.decode("LETHAL2-eJwljbEOgzAMRH8lutlCJdAO2VpBf4ARIRRCKFUhIAJDhfLvNXSxfXp35x0Gaj8GjEzjiwGhZZFZPYhEtHrULxuJ-zwPXyHFY1tcxBYLFRM6qLJEdnpAO_7uWo_T5laoJFTE2DZb1534vGpvrOM8ji6u8qs2Hw8lQ1URHIN8bOwinm-_IhBmfnKjlOSVJKEYtO85lZt-4lWYaTE9qvADD387xA")
	_check(not ember.has("error") and ember["cards"].size() == 1 and ember["card"]["name"] == "Ember Fist"
		and ember["puzzle"]["card_copies"] == [2] and ember["puzzle"]["other_cards"].size() == 3,
		"share code: earlier one-card code: %s" % _json(ember))

	# Codes made before the compact format still import.
	var v1 := _raw_code({"card": card, "puzzle": {"hp": 9, "other_cards": ["Echo"]}}, 1)
	var old := ShareCode.decode(v1)
	_check(not old.has("error") and old["card"]["name"] == "Shared" and old["puzzle"]["hp"] == 9
		and _json(old["puzzle"]["other_cards"]) == _json(["res://Scenes/EchoCard.tscn"]),
		"share code: LETHAL1 code: %s" % _json(old))

## A code made from any data, as someone editing one by hand could (version 2,
## or 1 for the old gzip codes).
func _raw_code(data, version := 2) -> String:
	var mode := FileAccess.COMPRESSION_DEFLATE if version == 2 else FileAccess.COMPRESSION_GZIP
	var packed := JSON.stringify(data).to_utf8_buffer().compress(mode)
	var prefix := ShareCode.PREFIX if version == 2 else ShareCode.PREFIX_V1
	return prefix + Marshalls.raw_to_base64(packed).replace("+", "-").replace("/", "_").replace("=", "")

func _json(value) -> String:
	return JSON.stringify(value, "", true)


func _test_registry() -> void:
	var ids := EffectRegistry.get_effect_ids()
	_check(ids.size() >= 40, "registry found only %d effects" % ids.size())
	for id in ids:
		var effect := EffectRegistry.create_effect({"type": id})
		_check(effect != null, "effect %s: can't be built from defaults" % id)
		if effect == null:
			continue
		var described := EffectRegistry.describe_effect(effect)
		_check(_json(described) == _json({"type": id}), "effect %s: defaults don't describe as {type}: %s" % [id, _json(described)])
		effect.free()
	print("registry: %d effects" % ids.size())


func _builtin_card_paths() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at("res://Scenes/"):
		if file.ends_with("Card.tscn") and not file.ends_with("CardEffect.tscn") and file != "Card.tscn":
			paths.append("res://Scenes/" + file)
	paths.sort()
	return paths

func _test_builtin_round_trip() -> void:
	var count := 0
	for path in _builtin_card_paths():
		var original = load(path).instantiate()
		if not (original is Card):
			original.free()
			continue
		count += 1
		var definition := CardFactory.describe_card(original)
		var rebuilt := CardFactory.create_card(definition)
		var again := CardFactory.describe_card(rebuilt)
		_check(_json(definition) == _json(again), "card %s: round trip differs\n      original: %s\n      rebuilt:  %s" % [path.get_file(), _json(definition), _json(again)])
		original.free()
		rebuilt.free()
	print("built-in cards round-tripped: %d" % count)
	_test_gradients()


## Card data stores colors as hex, so channels can be off by one 255th.
func _same_colors(a: PackedColorArray, b: PackedColorArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		for channel in 4:
			if absf(a[i][channel] - b[i][channel]) > 1.5 / 255.0:
				return false
	return true

## Two-color cards built from data must look like the built-in ones (same colors,
## blend points and direction), and each must keep its own colors.
func _test_gradients() -> void:
	var count := 0
	var rebuilt_cards: Array[Card] = []
	var expected_colors: Array = []
	for path in _builtin_card_paths():
		var original = load(path).instantiate()
		if not (original is Card and original.has_gradient_background()):
			original.free()
			continue
		count += 1
		var rebuilt := CardFactory.create_card(CardFactory.describe_card(original))
		var want: GradientTexture2D = original.get_gradient_background_texture()
		var got: GradientTexture2D = rebuilt.get_gradient_background_texture() if rebuilt.has_gradient_background() else null
		var name := path.get_file()
		_check(got != null, "gradient %s: rebuilt card has no gradient" % name)
		if got != null:
			_check(_same_colors(got.gradient.colors, want.gradient.colors), "gradient %s: colors %s, want %s" % [name, got.gradient.colors, want.gradient.colors])
			var offsets_match := got.gradient.offsets.size() == want.gradient.offsets.size()
			for i in mini(got.gradient.offsets.size(), want.gradient.offsets.size()):
				offsets_match = offsets_match and absf(got.gradient.offsets[i] - want.gradient.offsets[i]) < 0.01
			# Drain's scene blends 18-92% instead of the usual 18-82%; card data doesn't
			# store blend points, so its data-built twin uses the usual ones.
			_check(offsets_match or name in GRADIENT_LAYOUT_EXCEPTIONS, "gradient %s: blend points %s, want %s" % [name, got.gradient.offsets, want.gradient.offsets])
			_check(got.fill_from == want.fill_from and got.fill_to == want.fill_to, "gradient %s: direction %s->%s, want %s->%s" % [name, got.fill_from, got.fill_to, want.fill_from, want.fill_to])
			rebuilt_cards.append(rebuilt)
			expected_colors.append(want.gradient.colors)
		original.free()
	# Built one after another, every card must still show its own colors.
	for i in rebuilt_cards.size():
		_check(_same_colors(rebuilt_cards[i].get_gradient_background_texture().gradient.colors, expected_colors[i]),
			"gradient: card %d's colors changed when another gradient card was built" % i)
		rebuilt_cards[i].free()
	print("two-color cards checked: %d" % count)


func _build_with_card_lab(data: Dictionary) -> Card:
	var card_lab = load(CARD_LAB_SCRIPT).new()
	var card: Card = load(CardFactory.GENERIC_CARD_SCENE).instantiate()
	card_lab._configure_card(card, data)
	card_lab.free()
	return card

func _load_samples() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string(SAMPLES_PATH))

func _capture_card_lab_golden() -> void:
	var golden: Array = []
	for data in _load_samples():
		var card := _build_with_card_lab(data)
		golden.append(CardFactory.describe_card(card))
		card.free()
	var file := FileAccess.open(GOLDEN_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(golden, " ", true) + "\n")
	file.close()
	print("Recorded %d Card Lab cards to %s" % [golden.size(), GOLDEN_PATH])

func _test_card_lab_golden() -> void:
	if not FileAccess.file_exists(GOLDEN_PATH):
		_check(false, "missing %s (run with --capture-card-lab)" % GOLDEN_PATH)
		return
	var golden: Array = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	var samples := _load_samples()
	for i in samples.size():
		var card := _build_with_card_lab(samples[i])
		var built := CardFactory.describe_card(card)
		# Round-trip through JSON so number types match the stored file.
		var built_json := _json(JSON.parse_string(JSON.stringify(built)))
		_check(i < golden.size() and built_json == _json(golden[i]), "Card Lab sample %d (%s) differs from golden\n      golden: %s\n      built:  %s" % [i, samples[i].get("name"), _json(golden[i]) if i < golden.size() else "-", built_json])
		card.free()
	print("Card Lab samples matched golden: %d" % samples.size())


func _test_card_lab_registry_effects() -> void:
	# Effect types the old Card Lab couldn't express, via the registry.
	var data := {
		"name": "Lab Gamble", "energy": 1, "description": "Choose: heal 2 or deal 4.",
		"effects": [
			{"type": "PlayerChooseEffect", "params": {"card_effects_to_choose_from": [
				{"type": "Heal", "params": {"heal_amount": 2}},
				{"type": "Damage", "params": {"damage_amount": 4}},
			]}},
			{"type": "Condition", "params": {"condition_object": "Energy", "threshold_amount": 2},
				"children": [{"type": "Draw", "params": {"draw_amount": 2}}]},
			{"type": "PickToCreate", "params": {"card_scenes": ["Slash", "Pound"]}},
		],
	}
	var card := _build_with_card_lab(data)
	var described := CardFactory.describe_card(card)
	var effects: Array = described["effects"]
	_check(effects.size() == 3, "registry effects via Card Lab: expected 3 effects, got %d" % effects.size())
	if effects.size() == 3:
		_check(_json(effects[0]) == _json(data["effects"][0]), "Card Lab PlayerChooseEffect: %s" % _json(effects[0]))
		_check(_json(effects[1]) == _json(data["effects"][1]), "Card Lab Condition: %s" % _json(effects[1]))
		_check(_json(effects[2]) == _json(data["effects"][2]), "Card Lab PickToCreate: %s" % _json(effects[2]))
	card.free()
	print("Card Lab registry effects: checked")
	_test_no_outside_files()


## Card data names buffs, debuffs, cards and icons; it must never make the game
## load any other file (a shared puzzle link is untrusted).
func _test_no_outside_files() -> void:
	# Allowed: names, and the old path forms of the same scenes.
	_check(EffectRegistry.allowed_scene_path("buff_scene", "Sharp") == "res://Scenes/SharpBuff.tscn", "allowed: buff by name")
	_check(EffectRegistry.allowed_scene_path("buff_scene", "res://Scenes/SharpBuff.tscn") == "res://Scenes/SharpBuff.tscn", "allowed: old buff path")
	_check(EffectRegistry.allowed_scene_path("card_to_create_scene", "res://Scenes/ArmoryCard.scn") == "res://Scenes/ArmoryCard.tscn", "allowed: web Card Lab .scn card path")
	_check(EffectRegistry.allowed_scene_path("debuff_scene", "Burn") == "res://Scenes/BurnDebuff.tscn", "allowed: debuff by name")
	# Refused: anything that isn't one of those scenes.
	for bad in ["res://Scenes/Puzzles/Kraken-Puzzle.tscn", "res://project.godot", "user://evil.tscn",
			"C:/Users/evil.tscn", "res://Scenes/../evil.tscn", "res://Scenes/SharpBuff.tscn/../../evil.tscn",
			"res://Scenes/BurnDebuff.tscn"]:
		_check(EffectRegistry.allowed_scene_path("buff_scene", bad).is_empty(), "refused as a buff: " + bad)
	_check(EffectRegistry.allowed_scene_path("card_to_create_scene", "res://Scenes/SharpBuff.tscn").is_empty(), "refused: a buff as a card")
	# Through a whole card: the bad entries are dropped, the rest still builds.
	var card := CardFactory.create_card({"name": "Sneaky", "energy": 1, "description": "x",
		"icon": "../../project.godot",
		"effects": [
			{"type": "CreateCard", "params": {"card_to_create_scene": "user://evil.tscn"}},
			{"type": "PickToCreate", "params": {"card_scenes": ["Slash", "res://evil.tscn", "C:/evil.tscn"]}},
			{"type": "Buff", "params": {"buff_scene": "Sharp", "buff_params": {"sharp_count": 2, "script": "res://evil.gd", "target": "x"}}},
		]})
	var described := CardFactory.describe_card(card)
	var effects: Array = described["effects"]
	_check(not effects[0].get("params", {}).has("card_to_create_scene"), "CreateCard kept a refused card: %s" % _json(effects[0]))
	_check(_json(effects[1].get("params", {}).get("card_scenes", [])) == _json(["Slash"]), "PickToCreate kept refused cards: %s" % _json(effects[1]))
	_check(_json(effects[2].get("params", {}).get("buff_params", {})) == _json({"sharp_count": 2}), "Buff kept settings that aren't the buff's own: %s" % _json(effects[2]))
	_check(not str(described.get("icon", "")).contains("project.godot"), "icon outside res://Assets/ was used")
	card.free()
	print("outside files refused: checked")
