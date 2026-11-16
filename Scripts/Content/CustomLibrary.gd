class_name CustomLibrary
## The player's custom cards and custom puzzles (made in the Card Lab or imported from a share
## code). Local to this device: user://custom_library.json. They show in the Library next to
## the game's own, marked CUSTOM.
##
## card:   {"id": "card-3", "def": <CardFactory definition>, "author": "...", "added": "YYYY-MM-DD"}
## puzzle: {"id": "puzzle-2", "name", "author", "hp", "energy", "enemy_hp", "added",
##          "hand": [{"card": "card-3"} or {"builtin": "Slash"}, ...]}  (the hand in order)

const PATH := "user://custom_library.json"
const GENERIC_CARD_SIZE := Vector2(120, 160)

static var _data: Dictionary = {}

static func _ensure_loaded() -> void:
	if not _data.is_empty():
		return
	_data = {"cards": [], "puzzles": [], "next_id": 1}
	if FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			for key in ["cards", "puzzles"]:
				if parsed.get(key) is Array:
					_data[key] = parsed[key]
			_data["next_id"] = int(parsed.get("next_id", 1))

static func _save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_data, " "))

static func _new_id(kind: String) -> String:
	var id := "%s-%d" % [kind, int(_data["next_id"])]
	_data["next_id"] = int(_data["next_id"]) + 1
	return id

static func cards() -> Array:
	_ensure_loaded()
	return _data["cards"]

static func puzzles() -> Array:
	_ensure_loaded()
	return _data["puzzles"]

static func card(id: String) -> Dictionary:
	for entry in cards():
		if entry["id"] == id:
			return entry
	return {}

static func puzzle(id: String) -> Dictionary:
	for entry in puzzles():
		if entry["id"] == id:
			return entry
	return {}

## Adds what a share code holds (ShareCode.decode_library). With include_puzzles false,
## only the cards. A card already in the library (same card, same author) isn't added twice,
## and neither is a puzzle. Returns {"cards": added, "puzzles": added}.
static func add(decoded: Dictionary, include_puzzles: bool = true) -> Dictionary:
	_ensure_loaded()
	var today := Time.get_date_string_from_system()
	var ids: Array = []  # index in decoded["cards"] -> library card id
	var added_cards := 0
	for shared in decoded.get("cards", []):
		var existing := _find_card(shared["def"], str(shared.get("author", "")))
		if existing.is_empty():
			existing = {"id": _new_id("card"), "def": shared["def"], "author": str(shared.get("author", "")), "added": today}
			_data["cards"].append(existing)
			added_cards += 1
		ids.append(existing["id"])
	var added_puzzles := 0
	if include_puzzles:
		for shared in decoded.get("puzzles", []):
			var hand: Array = []
			for token in shared["hand"]:
				hand.append({"card": ids[token]} if token is int else {"builtin": str(token)})
			var entry := {"name": str(shared.get("name", "Custom puzzle")), "author": str(shared.get("author", "")),
				"hp": int(shared.get("hp", 10)), "energy": int(shared.get("energy", 5)), "enemy_hp": int(shared.get("enemy_hp", 20)),
				"hand": hand}
			if _find_puzzle(entry).is_empty():
				entry["id"] = _new_id("puzzle")
				entry["added"] = today
				_data["puzzles"].append(entry)
				added_puzzles += 1
	_save()
	return {"cards": added_cards, "puzzles": added_puzzles}

## A card or puzzle name, compared without case or outside spaces.
static func _key(name) -> String:
	return str(name).strip_edges().to_lower()

static func card_named(name: String) -> Dictionary:
	for entry in cards():
		if _key(entry["def"].get("name", "")) == _key(name):
			return entry
	return {}

## The custom puzzle with this name (any case), or {}.
static func puzzle_named(name: String) -> Dictionary:
	for entry in puzzles():
		if _key(entry.get("name", "")) == _key(name):
			return entry
	return {}

## What saving these would overwrite: the names of cards and puzzles already in the Library
## that differ from the ones coming in (identical ones aren't a conflict).
static func conflicts(decoded: Dictionary, include_puzzles: bool = true) -> Dictionary:
	var found := {"cards": [], "puzzles": []}
	for shared in decoded.get("cards", []):
		var existing := card_named(str(shared["def"].get("name", "")))
		if not existing.is_empty() and (JSON.stringify(existing["def"], "", true) != JSON.stringify(shared["def"], "", true)
				or str(existing.get("author", "")) != str(shared.get("author", ""))):
			if str(existing["def"].get("name", "")) not in found["cards"]:
				found["cards"].append(str(existing["def"].get("name", "")))
	if include_puzzles:
		for shared in decoded.get("puzzles", []):
			var existing := puzzle_named(str(shared.get("name", "")))
			if not existing.is_empty() and not _same_puzzle(existing, shared, decoded.get("cards", [])) 					and str(existing["name"]) not in found["puzzles"]:
				found["puzzles"].append(str(existing["name"]))
	return found

## A saved puzzle and an incoming one (its hand: indexes into shared_cards, or built-in
## names) are the same: same numbers, author and hand (cards compared by name).
static func _same_puzzle(entry: Dictionary, shared: Dictionary, shared_cards: Array) -> bool:
	for key in ["hp", "energy", "enemy_hp", "difficulty"]:
		if int(entry.get(key, 0)) != int(shared.get(key, 0)):
			return false
	if str(entry.get("author", "")) != str(shared.get("author", "")):
		return false
	var saved: Array = []
	for slot in entry.get("hand", []):
		if slot.has("card"):
			saved.append(_key(card(str(slot["card"])).get("def", {}).get("name", "")))
		else:
			saved.append("b:" + str(slot.get("builtin", "")))
	var incoming: Array = []
	for token in shared.get("hand", []):
		if token is int:
			incoming.append(_key(shared_cards[token]["def"].get("name", "")))
		else:
			incoming.append("b:" + str(token))
	return saved == incoming

## Saves cards (and, with include_puzzles, puzzles) from the Puzzle Lab or a share code
## (ShareCode.decode_library's shape). Names are unique: a card or puzzle with the same name
## as one already here replaces it (same id, so puzzles using a card keep working); ask the
## player first (conflicts()). Returns {"cards": added, "updated": cards replaced,
## "puzzles": added, "replaced": puzzles replaced}.
static func save(decoded: Dictionary, include_puzzles: bool = true) -> Dictionary:
	_ensure_loaded()
	var today := Time.get_date_string_from_system()
	var ids: Array = []
	var result := {"cards": 0, "updated": 0, "puzzles": 0, "replaced": 0}
	for shared in decoded.get("cards", []):
		var author := str(shared.get("author", ""))
		var existing := card_named(str(shared["def"].get("name", "")))
		if existing.is_empty():
			existing = {"id": _new_id("card"), "def": shared["def"], "author": author, "added": today}
			_data["cards"].append(existing)
			result["cards"] += 1
		elif JSON.stringify(existing["def"], "", true) != JSON.stringify(shared["def"], "", true) or existing.get("author", "") != author:
			existing["def"] = shared["def"]
			existing["author"] = author
			result["updated"] += 1
		ids.append(existing["id"])
	if include_puzzles:
		for shared in decoded.get("puzzles", []):
			var hand: Array = []
			for token in shared["hand"]:
				hand.append({"card": ids[token]} if token is int else {"builtin": str(token)})
			var fields := {"name": str(shared.get("name", "Custom puzzle")), "author": str(shared.get("author", "")),
				"hp": int(shared.get("hp", 10)), "energy": int(shared.get("energy", 5)), "enemy_hp": int(shared.get("enemy_hp", 20)),
				"difficulty": clampi(int(shared.get("difficulty", 0)), 0, 5), "hand": hand}
			var existing := puzzle_named(fields["name"])
			if existing.is_empty():
				fields["id"] = _new_id("puzzle")
				fields["added"] = today
				_data["puzzles"].append(fields)
				result["puzzles"] += 1
			elif JSON.stringify(fields) != JSON.stringify({"name": existing["name"], "author": existing.get("author"),
					"hp": existing["hp"], "energy": existing["energy"], "enemy_hp": existing["enemy_hp"],
					"difficulty": int(existing.get("difficulty", 0)), "hand": existing["hand"]}):
				existing.merge(fields, true)
				result["replaced"] += 1
	_save()
	return result

## A short list for a confirm box: "the puzzle "Dummy" and the cards "Zap" and "Brew"".
static func describe_conflicts(found: Dictionary) -> String:
	var parts: Array = []
	for kind in ["puzzles", "cards"]:
		var names: Array = found[kind].map(func(n): return "\"%s\"" % n)
		if names.is_empty():
			continue
		var noun: String = kind.trim_suffix("s") if names.size() == 1 else kind
		var listed: String = names[0] if names.size() == 1 else ", ".join(names.slice(0, -1)) + " and " + names[-1]
		parts.append("the %s %s" % [noun, listed])
	return " and ".join(parts)

static func _find_card(def: Dictionary, author: String) -> Dictionary:
	var key := JSON.stringify(def, "", true)
	for entry in cards():
		if entry.get("author", "") == author and JSON.stringify(entry["def"], "", true) == key:
			return entry
	return {}

static func _find_puzzle(candidate: Dictionary) -> Dictionary:
	for entry in puzzles():
		var same := true
		for key in ["name", "author", "hp", "energy", "enemy_hp", "hand"]:
			if JSON.stringify(entry.get(key)) != JSON.stringify(candidate.get(key)):
				same = false
		if same:
			return entry
	return {}

## The custom puzzles that deal this card.
static func puzzles_using(card_id: String) -> Array:
	return puzzles().filter(func(p): return p["hand"].any(func(slot): return slot.get("card", "") == card_id))

## Deletes a card; not while a custom puzzle uses it (returns false).
static func remove_card(id: String) -> bool:
	if not puzzles_using(id).is_empty():
		return false
	_data["cards"] = cards().filter(func(entry): return entry["id"] != id)
	_save()
	return true

static func remove_puzzle(id: String) -> void:
	_data["puzzles"] = puzzles().filter(func(entry): return entry["id"] != id)
	_save()

## A share code with these cards and puzzles (a puzzle's custom cards always come along).
static func share_code(card_ids: Array, puzzle_ids: Array) -> String:
	var wanted: Array = card_ids.duplicate()
	for puzzle_id in puzzle_ids:
		for slot in puzzle(puzzle_id).get("hand", []):
			if slot.has("card") and slot["card"] not in wanted:
				wanted.append(slot["card"])
	var shared_cards: Array = []
	var index := {}
	for id in wanted:
		var entry := card(id)
		if not entry.is_empty():
			index[id] = shared_cards.size()
			shared_cards.append({"def": entry["def"], "author": entry.get("author", "")})
	var shared_puzzles: Array = []
	for puzzle_id in puzzle_ids:
		var entry := puzzle(puzzle_id)
		if entry.is_empty():
			continue
		var hand: Array = []
		for slot in entry["hand"]:
			if slot.has("card") and index.has(slot["card"]):
				hand.append(index[slot["card"]])
			elif slot.has("builtin"):
				hand.append(slot["builtin"])
		shared_puzzles.append({"name": entry["name"], "author": entry.get("author", ""), "hp": entry["hp"],
			"energy": entry["energy"], "enemy_hp": entry["enemy_hp"], "difficulty": int(entry.get("difficulty", 0)), "hand": hand})
	return ShareCode.encode_library(shared_cards, shared_puzzles)

## A custom puzzle as a puzzle link's query (built-in cards in "cards", custom ones in
## "custom_cards", the order in "card_order"), the way the Card Lab plays its test hand.
static func puzzle_search(entry: Dictionary) -> String:
	var dealt: Array = []
	var card_names: Array = []
	var order: Array = []
	for slot in entry.get("hand", []):
		if slot.has("card"):
			var custom := card(slot["card"])
			if custom.is_empty():
				continue
			order.append("C%d" % dealt.size())
			dealt.append(custom["def"])
		else:
			var path := EffectRegistry.allowed_scene_path("card_scene", str(slot.get("builtin", "")))
			if path.is_empty():
				continue
			order.append("E%d" % card_names.size())
			card_names.append(path.get_file().trim_suffix("Card.tscn").to_lower() + "-card.PNG")
	return "?cards=%s&php=%d&pnrg=%d&ehp=%d&enemy_name=%s&author=%s&card_order=%s&custom_cards=%s" % [
		Marshalls.utf8_to_base64(",".join(card_names).uri_encode()).uri_encode(),
		int(entry.get("hp", 10)), int(entry.get("energy", 5)), int(entry.get("enemy_hp", 20)),
		str(entry.get("name", "Custom puzzle")).uri_encode(), str(entry.get("author", "")).uri_encode(),
		Marshalls.utf8_to_base64(JSON.stringify(order)).uri_encode(),
		Marshalls.utf8_to_base64(JSON.stringify(dealt)).uri_encode(),
	]

## The names of a puzzle's cards, in hand order (custom cards by their own name).
static func hand_names(entry: Dictionary) -> Array:
	var names: Array = []
	for slot in entry.get("hand", []):
		if slot.has("card"):
			names.append(str(card(slot["card"]).get("def", {}).get("name", "?")))
		else:
			var path := EffectRegistry.allowed_scene_path("card_scene", str(slot.get("builtin", "")))
			var info := CardFaces.info(str(slot.get("builtin", "")))
			names.append(str(info.get("name", slot.get("builtin", "?"))) if not path.is_empty() else str(slot.get("builtin", "?")))
	return names

## A custom card's details, like CardFaces.info(): name, cost, description, tips, colors.
static func card_info(id: String) -> Dictionary:
	var entry := card(id)
	if entry.is_empty():
		return {}
	var built: Card = CardFactory.create_card(entry["def"])
	var info := CardFaces._read(built, "")
	built.free()
	return info

## A custom card's face, as it looks in a hand (no game logic), or null.
static func make_face(id: String) -> Control:
	var entry := card(id)
	if entry.is_empty():
		return null
	var built: Card = CardFactory.create_card(entry["def"])
	if built.has_method("update_description_panel"):
		built.update_description_panel()
	built.get_node("TitlePanel/Title").set_text("[center]%s[/center]" % built.card_name)
	built.set_energy_text(built.energy_cost)
	for child in built.get_children():
		if child is CardEffect or child is Area2D:
			built.remove_child(child)
			child.free()
	built.set_script(null)
	built.size = GENERIC_CARD_SIZE
	return built
