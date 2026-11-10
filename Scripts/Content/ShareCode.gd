extends RefCounted
class_name ShareCode

## Card Lab share codes: a custom card plus its test puzzle as one line of text
## people paste to each other (Discord, chat). No server involved.
##
## Format (LETHAL2): "LETHAL2-" + base64url(deflate(JSON)), the JSON kept small:
##   one card:   {"c": <card>, "p": [hp, energy, enemy_hp, copies, "Slash", "Echo", ...]}
##   several:    {"c": [<card>, <card>], "p": [hp, energy, enemy_hp, [copies, copies], "Slash", ...]}
##   "o" (left out when the hand is your cards then the built-in ones): the hand's
##   order, i = the i-th custom card, -1 - k = the k-th built-in card.
## <card> is a CardFactory definition with one-letter keys (CARD_KEYS), the color
## without "#" (and without a solid "ff" alpha), the template left out when it's
## the same as the description, and each effect as [type, params?, children?].
## Built-in cards are stored by name, never by file path.
##
## LETHAL1 codes ("LETHAL1-" + base64url(gzip({"card": ..., "puzzle": {...}})))
## still import.
##
## Codes come from other people, so decode() treats them as untrusted: size
## limits, only known built-in card names, numbers clamped. The card itself is
## made safe by CardFactory / EffectRegistry when it's built.

const PREFIX := "LETHAL2-"
const PREFIX_V1 := "LETHAL1-"
const MAX_CODE_LENGTH := 60000
const MAX_JSON_BYTES := 200000
const MAX_OTHER_CARDS := 40
const MAX_COPIES := 20
const MAX_NUMBER := 999
const MAX_EFFECT_DEPTH := 16
const MAX_CUSTOM_CARDS := 10

## Card definition keys -> their short form. Keys not listed are kept as they are
## (always longer than one letter, so they can't clash). Never reuse a letter.
const CARD_KEYS := {
	"name": "n", "energy": "e", "color": "c", "description": "d",
	"description_template": "t", "effects": "f", "icon": "i", "gradient": "g",
	"colors": "k", "card_effect_delay": "y", "break_effects_on_apply": "b",
	"pay_cost_after_effects": "a",
}

## cards: one card definition, or a list of them (the puzzle's custom cards).
## puzzle: {"hp", "energy", "enemy_hp", "copies", "card_copies", "other_cards", "order"?}:
## card_copies is how many of each custom card (else "copies" for each),
## other_cards may hold scene paths or names, and order is the hand's order (see "o").
static func encode(cards, puzzle: Dictionary) -> String:
	var card_list: Array = [cards] if cards is Dictionary else cards
	var copies: Array = []
	var listed_copies = puzzle.get("card_copies", [])
	for i in card_list.size():
		var count = listed_copies[i] if listed_copies is Array and i < listed_copies.size() else puzzle.get("copies", 1)
		copies.append(int(count))
	var listed_others: Array = []
	for card_ref in puzzle.get("other_cards", []):
		var path := EffectRegistry.allowed_scene_path("card_scene", str(card_ref))
		if not path.is_empty():
			listed_others.append(path)
	var settings: Array = [
		int(puzzle.get("hp", 10)), int(puzzle.get("energy", 5)), int(puzzle.get("enemy_hp", 20)),
		copies[0] if card_list.size() == 1 else copies,
	]
	for path in listed_others:
		settings.append(EffectRegistry.scene_name(path))
	var packed_cards: Array = card_list.map(func(card): return _pack_card(card))
	var data := {"c": packed_cards[0] if packed_cards.size() == 1 else packed_cards, "p": settings}
	var order = puzzle.get("order")
	if order is Array and _order_fits(order, copies, listed_others.size()) 			and order != _default_order(copies, listed_others.size()):
		data["o"] = order.map(func(token): return int(token))
	var packed := JSON.stringify(data).to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	return PREFIX + _to_base64url(packed)

## Returns {"cards": [card, ...], "card": the first card,
## "puzzle": {..., "copies", "card_copies": [one per card], "other_cards": [scene paths]}}
## or {"error": "why it can't be read"}.
static func decode(code: String) -> Dictionary:
	var text := code.strip_edges()
	# Pasted from chat it may have line breaks or spaces in it.
	for whitespace in ["\n", "\r", " ", "\t", "`"]:
		text = text.replace(whitespace, "")
	if text.is_empty():
		return {"error": "Paste a share code first."}
	var version := 0
	if text.begins_with(PREFIX):
		version = 2
	elif text.begins_with(PREFIX_V1):
		version = 1
	else:
		return {"error": "That isn't a Card Lab share code (they start with %s)." % PREFIX}
	if text.length() > MAX_CODE_LENGTH:
		return {"error": "That code is too long."}
	var damaged := {"error": "That code is damaged. Copy it again, all of it."}
	var packed := _from_base64url(text.substr(PREFIX.length()))
	if packed.is_empty():
		return damaged
	var mode := FileAccess.COMPRESSION_DEFLATE if version == 2 else FileAccess.COMPRESSION_GZIP
	var raw := packed.decompress_dynamic(MAX_JSON_BYTES, mode)
	if raw.is_empty():
		return damaged
	var data = JSON.parse_string(raw.get_string_from_utf8())
	if not (data is Dictionary):
		return damaged

	var cards: Array = []
	var puzzle := {}
	var listed: Array = []
	if version == 2:
		var packed_cards = data.get("c")
		for entry in (packed_cards if packed_cards is Array else [packed_cards]).slice(0, MAX_CUSTOM_CARDS):
			var card = _unpack_card(entry)
			if card is Dictionary:
				cards.append(card)
		var settings = data.get("p", [])
		if settings is Array:
			var keys := ["hp", "energy", "enemy_hp", "copies"]
			for i in mini(keys.size(), settings.size()):
				puzzle[keys[i]] = settings[i]
			listed = settings.slice(keys.size())
	else:
		if data.get("card") is Dictionary:
			cards.append(data["card"])
		if data.get("puzzle") is Dictionary:
			puzzle = data["puzzle"]
			if puzzle.get("other_cards") is Array:
				listed = puzzle["other_cards"]
	if cards.is_empty():
		return damaged
	# Copies: one number for every card, or one per card.
	var copies_value = puzzle.get("copies")
	var card_copies: Array = []
	for i in cards.size():
		var count = copies_value[i] if copies_value is Array and i < copies_value.size() else copies_value
		card_copies.append(_number(count, 1, 1, MAX_COPIES))

	var other_cards: Array = []
	var unknown: Array = []
	for card_name in listed.slice(0, MAX_OTHER_CARDS):
		var path := EffectRegistry.allowed_scene_path("card_scene", str(card_name))
		if path.is_empty():
			unknown.append(str(card_name))
		else:
			other_cards.append(path)
	var order = data.get("o")
	var result := {
		"cards": cards,
		"card": cards[0],
		"puzzle": {
			"hp": _number(puzzle.get("hp"), 10, 1, MAX_NUMBER),
			"energy": _number(puzzle.get("energy"), 5, 0, MAX_NUMBER),
			"enemy_hp": _number(puzzle.get("enemy_hp"), 20, 1, MAX_NUMBER),
			"copies": card_copies[0],
			"card_copies": card_copies,
			"other_cards": other_cards,
		},
	}
	if order is Array and _order_fits(order, card_copies, other_cards.size()):
		result["puzzle"]["order"] = order.map(func(token): return int(token))
	if not unknown.is_empty():
		result["unknown_cards"] = unknown  # e.g. from a newer version of the game
	return result

# ---------------------------------------------------------------- hand order

## The test hand as a list, in order: an int is one copy of the int-th custom
## card, a String a built-in card's scene path. From Test hand settings
## ({"card_copies" or "copies", "other_cards", "order"?}); without a valid
## order it's each custom card (as many as its copies), then the built-in ones.
static func hand_from(settings: Dictionary, card_count: int, default_others: Array = []) -> Array:
	var copies: Array = []
	var listed = settings.get("card_copies", [])
	for i in card_count:
		var count = listed[i] if listed is Array and i < listed.size() else settings.get("copies", 1)
		copies.append(_number(count, 1, 1, MAX_COPIES))
	var others: Array = settings.get("other_cards", default_others)
	others = others.duplicate() if others is Array else []
	var order = settings.get("order")
	if not (order is Array and _order_fits(order, copies, others.size())):
		order = _default_order(copies, others.size())
	var hand: Array = []
	for token in order:
		var at := int(token)
		hand.append(at if at >= 0 else str(others[-1 - at]))
	return hand

## Each custom card i once per copy, then built-in cards -1, -2, ...
static func _default_order(copies: Array, other_count: int) -> Array:
	var order: Array = []
	for i in copies.size():
		for n in int(copies[i]):
			order.append(i)
	for k in other_count:
		order.append(-1 - k)
	return order

## True when order holds exactly the hand those copies and built-in cards make.
static func _order_fits(order: Array, copies: Array, other_count: int) -> bool:
	if order.size() > MAX_CUSTOM_CARDS * MAX_COPIES + MAX_OTHER_CARDS:
		return false
	var mine := order.filter(func(t): return (t is int or t is float) and int(t) >= 0)
	var theirs := order.filter(func(t): return (t is int or t is float) and int(t) < 0)
	if mine.size() + theirs.size() != order.size() or theirs.size() != other_count:
		return false
	var counts: Array = []
	counts.resize(copies.size())
	counts.fill(0)
	for t in mine:
		if int(t) >= copies.size():
			return false
		counts[int(t)] += 1
	for i in copies.size():
		if counts[i] != int(copies[i]):
			return false
	var seen := {}
	for t in theirs:
		var k := -1 - int(t)
		if k >= other_count or seen.has(k):
			return false
		seen[k] = true
	return true

# ---------------------------------------------------------------- compact card

static func _pack_card(card: Dictionary) -> Dictionary:
	var packed := {}
	for key in card:
		var value = card[key]
		match key:
			"description_template":
				if value == card.get("description"):
					continue
			"color":
				value = _short_color(value)
			"effects":
				value = _pack_effects(value)
		packed[CARD_KEYS.get(key, key)] = value
	return packed

static func _unpack_card(packed) -> Variant:
	if not (packed is Dictionary):
		return null
	var long_keys := {}
	for key in CARD_KEYS:
		long_keys[CARD_KEYS[key]] = key
	var card := {}
	for short_key in packed:
		var key: String = long_keys.get(short_key, str(short_key))
		var value = packed[short_key]
		match key:
			"color":
				if value is String and not value.begins_with("#"):
					value = "#" + value
			"effects":
				value = _unpack_effects(value, 0)
		card[key] = value
	# A left-out template is the description; CardFactory reads it that way.
	return card

## "#c2410cff" -> "c2410c"; anything else unchanged.
static func _short_color(value) -> Variant:
	if not (value is String):
		return value
	var hex: String = value.trim_prefix("#")
	if hex.length() == 8 and hex.ends_with("ff"):
		hex = hex.left(6)
	return hex

## {"type": "Damage", "params": {...}, "children": [...]} -> ["Damage", {...}, [...]]
## (params left out when there are none and no children). An effect with any
## other key stays a dictionary.
static func _pack_effects(effects) -> Variant:
	if not (effects is Array):
		return effects
	var packed: Array = []
	for effect in effects:
		if not (effect is Dictionary) or effect.keys().any(func(k): return not k in ["type", "params", "children"]):
			packed.append(effect)
			continue
		var entry: Array = [effect.get("type", "")]
		var children = effect.get("children", [])
		var has_children: bool = children is Array and not children.is_empty()
		var params = effect.get("params", {})
		if has_children or (params is Dictionary and not params.is_empty()):
			entry.append(params)
		if has_children:
			entry.append(_pack_effects(children))
		packed.append(entry)
	return packed

static func _unpack_effects(packed, depth: int) -> Array:
	var effects: Array = []
	if not (packed is Array) or depth > MAX_EFFECT_DEPTH:
		return effects
	for entry in packed:
		if entry is Dictionary:
			effects.append(entry)
		elif entry is Array and not entry.is_empty():
			var effect := {"type": str(entry[0])}
			if entry.size() > 1 and entry[1] is Dictionary and not entry[1].is_empty():
				effect["params"] = entry[1]
			if entry.size() > 2:
				var children := _unpack_effects(entry[2], depth + 1)
				if not children.is_empty():
					effect["children"] = children
			effects.append(effect)
	return effects

# ---------------------------------------------------------------- helpers

static func _to_base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

static func _from_base64url(text: String) -> PackedByteArray:
	var body := text.replace("-", "+").replace("_", "/")
	while body.length() % 4 != 0:
		body += "="
	return Marshalls.base64_to_raw(body)

static func _number(value, fallback: int, low: int, high: int) -> int:
	if value is int or value is float:
		return clampi(int(value), low, high)
	return fallback
