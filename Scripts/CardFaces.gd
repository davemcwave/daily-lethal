class_name CardFaces
## Built-in cards for menus (the Cards screen, the Puzzle Archive's card previews): each card's
## details, and its face as it looks in a hand (the card scene with its script and effects
## removed, so it can be shown anywhere without a game around it).

static var _files: Dictionary = {}   # in-game card name -> scene file
static var _info: Dictionary = {}    # in-game card name -> details (see info())

## Every built-in card's in-game name (one each), sorted.
static func all_names() -> Array:
	_scan()
	var names: Array = _files.keys()
	names.sort()
	return names

## Card colors by name (a card's background; gradient cards have two).
const COLORS := {"Red": Color("#8c0127"), "Orange": Color("#c35300"), "Green": Color("#008c10"),
		"Blue": Color("#002a8c"), "Purple": Color("#8c008c")}

## {name, cost, description (BBCode), tips: [[name, text]], designer ("" for originals),
##  colors: ["Red", ...], file}
static func info(card_name: String) -> Dictionary:
	_scan()
	return _info.get(card_name, {})

## A new face for the card (a Control sized like a card in hand, 120 x 160 with its frame), or null.
static func make_face(card_name: String) -> Control:
	_scan()
	if not _files.has(card_name):
		return null
	var card = load("res://Scenes/" + _files[card_name]).instantiate()
	_prepare(card)
	for child in card.get_children():
		if child is CardEffect or child is Area2D:
			card.remove_child(child)
			child.free()
	card.set_script(null)
	return card

## Any card (a built-in one, or a custom one from CardFactory) as a face: its text and
## look filled in, then its script and effects removed. 120 x 160.
static func strip(card: Card) -> Control:
	_prepare(card)
	for child in card.get_children():
		if child is CardEffect or child is Area2D:
			card.remove_child(child)
			child.free()
	card.set_script(null)
	card.size = Vector2(120, 160)
	fit_text_when_shown(card)
	return card

## A face has no card script to shrink long text, so its name and description are fitted to
## their boxes once it's on screen (a custom card's long name would spill otherwise).
static func fit_text_when_shown(face: Control) -> void:
	face.tree_entered.connect(func():
		var fit := func():
			for path in ["TitlePanel/Title", "DescriptionPanel/Title"]:
				var label = face.get_node_or_null(path)
				if label is RichTextLabel:
					TextFit.fit(label, 12, 7)
		fit.call_deferred(), CONNECT_ONE_SHOT)

static func _scan() -> void:
	if not _files.is_empty():
		return
	for file in DirAccess.get_files_at("res://Scenes/"):
		file = file.trim_suffix(".remap")
		if not file.ends_with("Card.tscn") or file == "Card.tscn" or file.ends_with("CardEffect.tscn"):
			continue
		var card = load("res://Scenes/" + file).instantiate()
		var card_name := str(card.card_name) if card is Card else ""
		# Skip non-cards and placeholders; two scenes can share a name (an old copy): keep the
		# one whose file matches the name.
		var keep := card is Card and not card_name.is_empty() and card_name != "Empty"
		if keep and _files.has(card_name) and not file.to_lower().begins_with(card_name.to_lower().replace(" ", "")):
			keep = false
		if keep:
			_files[card_name] = file
			_info[card_name] = _read(card, file)
		card.free()

static func _prepare(card: Card) -> void:
	if card.has_method("update_description_panel"):
		card.update_description_panel()
	card.get_node("TitlePanel/Title").set_text("[center]%s[/center]" % card.card_name)
	card.set_energy_text(card.energy_cost)

static func _read(card: Card, file: String) -> Dictionary:
	_prepare(card)
	var tips: Array = []
	var seen: Array = []
	var designer := ""
	for effect in card.card_effects:
		if effect == null or effect.get_effect_description().is_empty():
			continue
		var tip_name: String = effect.get_effect_name().rstrip("0123456789 ")
		if tip_name == "Community Card":
			# "This card was designed by a community member: [color=gold]Name[/color]"
			designer = RegEx.create_from_string("\\[[^\\]]*\\]").sub(effect.get_effect_description(), "", true).get_slice(": ", 1).strip_edges()
			continue
		if tip_name not in seen:
			seen.append(tip_name)
			tips.append([tip_name, effect.get_effect_description()])
	for keyword in Keywords.find_in(card.card_description):
		if str(keyword[0]).to_lower() not in seen.map(func(s): return s.to_lower()):
			tips.append(keyword)
	var backgrounds: Array = [card.get_background_color()]
	if card.has_gradient_background():
		backgrounds = Array(card.get_gradient_background_texture().gradient.colors)
	var colors: Array = []
	for background in backgrounds:
		var name := _color_name(background)
		if name not in colors:
			colors.append(name)
	return {"name": card.card_name, "cost": card.energy_cost, "description": card.card_description,
			"tips": tips, "designer": designer, "colors": colors, "file": file}

## The nearest named color.
static func _color_name(color: Color) -> String:
	var best := ""
	var best_distance := INF
	for name in COLORS:
		var c: Color = COLORS[name]
		var distance := Vector3(color.r - c.r, color.g - c.g, color.b - c.b).length()
		if distance < best_distance:
			best_distance = distance
			best = name
	return best
