extends Control
## Cards (desktop main menu): every built-in card in one grid, shown as it looks in a hand,
## with filters like the Puzzle Archive's (search, cost, color, world, author, sort). Cards no
## released puzzle uses (test cards) are left out.
## Click a card for its details: what its keywords mean, the story world that introduces it,
## how many archive puzzles use it, and a button to open those puzzles in the Puzzle Archive.
## Every card is shown; none are hidden until met.

const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const HOUSE_TEXTURE: Texture2D = preload("res://Assets/Textures/house-white.png")
const STORY_PATH := "res://Data/story_worlds.json"
const CARD_SIZE := Vector2(120, 160)  # a card face (its frame included)
const CARD_SCALE := 0.75
const DETAIL_WIDTH := 270.0
const NOT_IN_STORY := "Not in the story"

const COLOR_PANEL := Color("#18181b")
const COLOR_BORDER := Color("#3f3f46")
const COLOR_TEXT := Color("#fafafa")
const COLOR_MUTED := Color("#a1a1aa")
const COLOR_GOLD := Color("#ffce4e")
const COLOR_CUSTOM := Color("#c084fc")  # custom cards (made in the Card Lab or imported): purple

@onready var background = $"/root/Background"
@onready var audio_handler = $"/root/AudioHandler"

var cards: Array = []               # CardFaces.info() + "slot", "world", "uses", "keywords"
var world_order: Array = []         # story worlds, in story order
var selected: Dictionary = {}

var grid: GridContainer
var search: LineEdit
var cost_filter: OptionButton
var world_filter: OptionButton
var color_toggles: Array = []   # swatch buttons; any pressed = cards with any of those colors
var author_filter: OptionButton
var sort_option: OptionButton
var source_filter: OptionButton
var detail: VBoxContainer
var count_label: Label

func _ready() -> void:
	var taught_in := _story_worlds()
	var uses := _puzzle_uses()
	var spellings := {}  # author lowercased -> the first spelling seen ("moribam" and "Moribam" are one author)
	for card_name in CardFaces.all_names():
		if uses.get(card_name, 0) == 0:
			continue  # no released puzzle uses it: a test card
		var info: Dictionary = CardFaces.info(card_name).duplicate()
		info["world"] = taught_in.get(card_name, NOT_IN_STORY)
		info["uses"] = uses.get(card_name, 0)
		info["keywords"] = info["tips"].map(func(tip): return str(tip[0]))
		# The card's author: the community member who designed it, else mcwavegames.
		info["author"] = info["designer"] if not str(info["designer"]).is_empty() else "mcwavegames"
		info["author"] = spellings.get(str(info["author"]).to_lower(), info["author"])
		spellings[str(info["author"]).to_lower()] = info["author"]
		cards.append(info)
	cards.append_array(_custom_cards())
	_build_ui()
	if not background.library_notice.is_empty():
		source_filter.select(2)  # just imported: show the custom cards
	_apply_filters()
	var first := cards.filter(func(info): return info["slot"].visible)
	if not first.is_empty():
		_select(first[0])
	LibraryImport.show_notice(self)

# ---------------------------------------------------------------- data

## Card name -> the story world that introduces it (and world_order filled in story order).
func _story_worlds() -> Dictionary:
	var taught_in := {}
	var story = JSON.parse_string(FileAccess.get_file_as_string(STORY_PATH))
	if story is Dictionary:
		for world in story.get("worlds", []):
			world_order.append(str(world["name"]))
			for card in world.get("cards", []):
				var card_name := "Cooperate" if card == "Cooperation" else str(card)
				if not taught_in.has(card_name):
					taught_in[card_name] = str(world["name"])
	return taught_in

## The player's custom cards (CustomLibrary), like the built-in ones' details.
func _custom_cards() -> Array:
	var custom_cards: Array = []
	for entry in CustomLibrary.cards():
		var info := CustomLibrary.card_info(str(entry["id"]))
		if info.is_empty():
			continue
		info["custom"] = true
		info["library_id"] = str(entry["id"])
		info["world"] = NOT_IN_STORY
		info["uses"] = CustomLibrary.puzzles_using(str(entry["id"])).size()
		info["keywords"] = info["tips"].map(func(tip): return str(tip[0]))
		info["author"] = str(entry.get("author", "")) if not str(entry.get("author", "")).is_empty() else "Unknown"
		custom_cards.append(info)
	return custom_cards

## Card name -> how many archive puzzles use it.
func _puzzle_uses() -> Dictionary:
	var uses := {}
	for entry in PuzzleArchive.load_bundled():
		var once := {}
		for card in entry.get("cards", []):
			once[card] = true
		for card in once:
			uses[card] = uses.get(card, 0) + 1
	return uses

# ---------------------------------------------------------------- filters and grid

func _apply_filters(_value = null) -> void:
	var words: Array = Array(search.text.strip_edges().to_lower().split(" ", false))
	var world := _choice(world_filter)
	var colors: Array = color_toggles.filter(func(b): return b.button_pressed).map(func(b): return b.get_meta("color"))
	var author := _choice(author_filter)
	var visible_cards: Array = []
	for info in cards:
		var custom: bool = info.get("custom", false)
		var text := ("%s %s %s %s %s %s" % [info["name"], _plain(info["description"]), info["world"], info["author"], " ".join(info["keywords"]),
			"custom" if custom else "official"]).to_lower()
		var ok := not words.any(func(word): return not text.contains(word))
		if source_filter.selected == 1:
			ok = ok and not custom
		elif source_filter.selected == 2:
			ok = ok and custom
		match cost_filter.selected:
			1: ok = ok and int(info["cost"]) == 0
			2: ok = ok and int(info["cost"]) == 1
			3: ok = ok and int(info["cost"]) == 2
			4: ok = ok and int(info["cost"]) >= 3
		if not world.is_empty():
			ok = ok and info["world"] == world
		if not colors.is_empty():
			ok = ok and colors.any(func(c): return c in info["colors"])
		if not author.is_empty():
			ok = ok and info["author"] == author
		info["slot"].visible = ok
		if ok:
			visible_cards.append(info)
	# Sort the grid.
	var order := cards.duplicate()
	match sort_option.selected:
		0: order.sort_custom(func(a, b): return str(a["name"]).to_lower() < str(b["name"]).to_lower())
		1: order.sort_custom(func(a, b): return a["cost"] < b["cost"] if a["cost"] != b["cost"] else a["name"] < b["name"])
		2: order.sort_custom(func(a, b): return a["uses"] > b["uses"] if a["uses"] != b["uses"] else a["name"] < b["name"])
		3: order.sort_custom(func(a, b): return _world_index(a) < _world_index(b) if _world_index(a) != _world_index(b) else a["name"] < b["name"])
	for i in order.size():
		grid.move_child(order[i]["slot"], i)
	count_label.text = "%d of %d cards" % [visible_cards.size(), cards.size()]

func _world_index(info: Dictionary) -> int:
	var at := world_order.find(info["world"])
	return at if at != -1 else 999

## The chosen option's text, or "" for the first ("Any ...") option.
func _choice(option: OptionButton) -> String:
	return str(option.get_item_metadata(option.selected)) if option.selected > 0 else ""

func _clear_filters() -> void:
	search.text = ""
	for option in [cost_filter, world_filter, author_filter, source_filter]:
		option.select(0)
	for toggle in color_toggles:
		toggle.set_pressed_no_signal(false)
	_apply_filters()

func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]*\\]").sub(bbcode, "", true)

func _select(info: Dictionary) -> void:
	if not selected.is_empty():
		selected["slot"].get_node("Highlight").hide()
	selected = info
	info["slot"].get_node("Highlight").show()
	for child in detail.get_children():
		child.queue_free()
	var custom: bool = info.get("custom", false)
	if custom:
		detail.add_child(_label("CUSTOM CARD", FONT_BOLD, 10, COLOR_CUSTOM))
	detail.add_child(_label(str(info["name"]), FONT_BOLD, 22, COLOR_TEXT))
	detail.add_child(_label("by " + str(info["author"]), FONT_MEDIUM, 12, COLOR_GOLD))
	detail.add_child(_label("Costs %d energy" % int(info["cost"]), FONT_MEDIUM, 12, COLOR_MUTED))
	detail.add_child(_rich(RegEx.create_from_string("\\[/?(shake|center)[^\\]]*\\]").sub(str(info["description"]), "", true), 14, COLOR_TEXT))
	if not info["tips"].is_empty():
		# A small heading: what follows explains the card's effects and keywords.
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		detail.add_child(gap)
		detail.add_child(_label("CARD EFFECTS", FONT_BOLD, 10, COLOR_MUTED))
		var rule := ColorRect.new()
		rule.color = COLOR_BORDER
		rule.custom_minimum_size = Vector2(0, 1)
		detail.add_child(rule)
	for tip in info["tips"]:
		detail.add_child(_rich("[b]%s:[/b] %s" % [tip[0], tip[1]], 12, Color("#d4d4d8")))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	detail.add_child(spacer)
	var uses: int = info["uses"]
	if custom:
		var note := _label("Made in the Puzzle Lab or imported from a share code. Only on this device.", FONT_MEDIUM, 11, COLOR_MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(note)
	if uses > 0:
		var open := _button("%sPUZZLES WITH THIS CARD (%d)" % ["CUSTOM " if custom else "", uses], true)
		open.pressed.connect(func():
			background.archive_preset_cards = [info["name"]]
			get_tree().change_scene_to_file(background.ARCHIVE_SCENE))
		detail.add_child(open)
	if custom:
		# Edit on its own row, Share and Delete under it: fits the panel's width.
		var edit := _button("Edit in Puzzle Lab", false)
		edit.pressed.connect(func():
			background.card_lab_incoming = [CustomLibrary.card(info["library_id"]).get("def", {})]
			get_tree().change_scene_to_file(background.CARD_BUILDER_SCENE))
		detail.add_child(edit)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		detail.add_child(row)
		var share := _button("Share code", false)
		share.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		share.pressed.connect(func():
			DisplayServer.clipboard_set(ShareCode.chat_code(CustomLibrary.share_code([info["library_id"]], [])))
			share.text = "Code copied")
		row.add_child(share)
		var delete := _button("Delete", false)
		delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(delete)
		var status := _label("", FONT_MEDIUM, 11, Color("#f87171"))
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(status)
		delete.pressed.connect(func():
			if uses > 0:
				status.text = "A custom puzzle uses this card. Delete the puzzle first (Library > Puzzles)."
				return
			if delete.text != "Delete?":
				_arm_delete(delete, true)  # asks once more, in red
				return
			_delete_custom(info))

## Removes a custom card from the Library and the grid.
func _delete_custom(info: Dictionary) -> void:
	if not CustomLibrary.remove_card(info["library_id"]):
		return
	cards.erase(info)
	info["slot"].queue_free()
	selected = {}
	for child in detail.get_children():
		child.queue_free()
	_apply_filters()
	if not cards.is_empty():
		_select(cards[0])

# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var page := MarginContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		page.add_theme_constant_override("margin_" + side, 12)
	add_child(page)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	page.add_child(column)

	# Top bar: Main Menu, title, count.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	var menu := _button("MAIN MENU", false)
	menu.icon = HOUSE_TEXTURE
	menu.add_theme_constant_override("icon_max_width", 14)
	menu.pressed.connect(func():
		if OS.has_feature("web"):
			background.open_site_home()  # the web build has no main menu
		else:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn"))
	top.add_child(menu)
	top.add_child(_library_tabs("Cards"))
	# Both sides of the tabs the same width, so the tabs stay centered.
	var side_width := 330.0  # room for Puzzle Lab and Import code
	var pad := Control.new()
	pad.custom_minimum_size.x = side_width - menu.get_combined_minimum_size().x
	top.add_child(pad)
	top.move_child(pad, menu.get_index() + 1)
	var right := HBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 10)
	right.custom_minimum_size.x = side_width
	count_label = _label("", FONT_MEDIUM, 12, COLOR_MUTED)
	count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	right.add_child(count_label)
	var lab := LibraryImport.lab_button(self)
	if lab != null:
		right.add_child(lab)
	right.add_child(LibraryImport.button(self, "res://Scenes/CardsView.tscn"))
	top.add_child(right)

	# Filters, like the Puzzle Archive's.
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	column.add_child(filters)
	search = LineEdit.new()
	search.placeholder_text = "Search anything..."
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(search)
	search.text_changed.connect(_apply_filters)
	filters.add_child(search)
	cost_filter = _option(["Any cost", "0 energy", "1 energy", "2 energy", "3+ energy"])
	filters.add_child(cost_filter)
	# Colors: swatch toggles; any number on, a card shows if it has any of them.
	var swatches := HBoxContainer.new()
	swatches.add_theme_constant_override("separation", 3)
	for color_name in CardFaces.COLORS:
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.custom_minimum_size = Vector2(26, 26)
		toggle.set_meta("color", color_name)
		var color: Color = CardFaces.COLORS[color_name]
		var off := _box(color, Color(color, 0.0))
		var on := _box(color, COLOR_GOLD)
		on.set_border_width_all(2)
		toggle.add_theme_stylebox_override("normal", off)
		toggle.add_theme_stylebox_override("hover", _box(color.lightened(0.15), Color("#71717a")))
		toggle.add_theme_stylebox_override("pressed", on)
		toggle.add_theme_stylebox_override("hover_pressed", on)
		toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		toggle.toggled.connect(_apply_filters)
		color_toggles.append(toggle)
		swatches.add_child(toggle)
	filters.add_child(swatches)
	var worlds: Array = world_order.duplicate()
	if cards.any(func(info): return info["world"] == NOT_IN_STORY):
		worlds.append(NOT_IN_STORY)
	world_filter = _option(["Any world"] + worlds)
	filters.add_child(world_filter)
	var authors := {}
	for info in cards:
		authors[info["author"]] = authors.get(info["author"], 0) + 1
	var author_names: Array = authors.keys()
	author_names.sort_custom(func(a, b): return authors[a] > authors[b] if authors[a] != authors[b] else a.to_lower() < b.to_lower())
	author_filter = _option(["Any author"] + author_names)
	filters.add_child(author_filter)
	source_filter = _option(["All sources", "Official", "Custom"])
	filters.add_child(source_filter)
	sort_option = _option(["Sort: name", "Sort: cost", "Sort: most used", "Sort: story order"])
	filters.add_child(sort_option)
	var clear := _button("Clear", false)
	clear.pressed.connect(_clear_filters)
	filters.add_child(clear)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	column.add_child(body)

	# The grid of card faces.
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", _box(Color("#111113"), COLOR_BORDER))
	body.add_child(scroll)
	var grid_margin := MarginContainer.new()
	grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		grid_margin.add_theme_constant_override("margin_" + side, 10)
	scroll.add_child(grid_margin)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_margin.add_child(grid)
	for info in cards:
		grid.add_child(_card_slot(info))

	# Details of the selected card.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	var detail_box := _box(Color("#111113"), COLOR_BORDER)
	detail_box.content_margin_left = 16
	detail_box.content_margin_right = 16
	detail_box.content_margin_top = 14
	detail_box.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", detail_box)
	body.add_child(panel)
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 6)
	panel.add_child(detail)

## A grid cell: the card face (scaled), a gold outline when selected, clickable.
func _card_slot(info: Dictionary) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = CARD_SIZE * CARD_SCALE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var custom: bool = info.get("custom", false)
	var face := CustomLibrary.make_face(info["library_id"]) if custom else CardFaces.make_face(info["name"])
	face.size = CARD_SIZE
	face.scale = Vector2(CARD_SCALE, CARD_SCALE)
	face.position = Vector2.ZERO
	_ignore_mouse(face)
	slot.add_child(face)
	var highlight := Panel.new()
	highlight.name = "Highlight"
	var outline := StyleBoxFlat.new()
	outline.draw_center = false
	outline.border_color = COLOR_GOLD
	outline.set_border_width_all(3)
	outline.set_corner_radius_all(6)
	highlight.add_theme_stylebox_override("panel", outline)
	highlight.position = Vector2(-3, -3)
	highlight.size = CARD_SIZE * CARD_SCALE + Vector2(6, 6)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.hide()
	slot.add_child(highlight)
	if custom:
		# A purple CUSTOM tag across the card's top-left corner.
		var tag := Label.new()
		tag.text = "CUSTOM"
		tag.add_theme_font_override("font", FONT_BOLD)
		tag.add_theme_font_size_override("font_size", 9)
		tag.add_theme_color_override("font_color", Color("#18181b"))
		var tag_box := StyleBoxFlat.new()
		tag_box.bg_color = COLOR_CUSTOM
		tag_box.set_corner_radius_all(3)
		tag_box.content_margin_left = 4
		tag_box.content_margin_right = 4
		tag.add_theme_stylebox_override("normal", tag_box)
		tag.position = Vector2(-4, -6)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tag)
	slot.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			audio_handler.play_sfx("GrabSFX")
			_select(info))
	info["slot"] = slot
	return slot

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _rich(bbcode: String, font_size: int, color: Color) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.text = bbcode
	text.add_theme_font_override("normal_font", FONT_MEDIUM)
	text.add_theme_font_override("bold_font", FONT_BOLD)
	text.add_theme_font_size_override("normal_font_size", font_size)
	text.add_theme_font_size_override("bold_font_size", font_size)
	text.add_theme_color_override("default_color", color)
	return text

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box

func _button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 13)
	var fg := Color("#18181b") if primary else COLOR_TEXT
	var bg := COLOR_GOLD if primary else COLOR_PANEL
	button.add_theme_stylebox_override("normal", _box(bg, COLOR_GOLD if primary else COLOR_BORDER))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), COLOR_GOLD if primary else Color("#52525b")))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.15), COLOR_BORDER))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, fg)
	button.add_theme_color_override("icon_normal_color", fg)
	return button

const COLOR_DANGER := Color("#dc2626")

## A Delete button's two looks: plain "Delete", then red "Delete?" (click again to confirm).
func _arm_delete(button: Button, armed: bool) -> void:
	button.text = "Delete?" if armed else "Delete"
	var bg := COLOR_DANGER if armed else COLOR_PANEL
	var border := COLOR_DANGER if armed else COLOR_BORDER
	button.add_theme_stylebox_override("normal", _box(bg, border))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), border if armed else Color("#52525b")))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.15), border))

func _option(items: Array) -> OptionButton:
	var option := OptionButton.new()
	for text in items:
		option.add_item(str(text))
		option.set_item_metadata(option.item_count - 1, str(text))
	option.add_theme_font_override("font", FONT_MEDIUM)
	option.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		option.add_theme_stylebox_override(state, _box(COLOR_PANEL if state != "hover" else Color("#27272a"), COLOR_BORDER))
	option.add_theme_color_override("font_color", COLOR_TEXT)
	option.add_theme_color_override("font_hover_color", COLOR_TEXT)
	option.fit_to_longest_item = false  # as wide as the chosen option, so the row fits
	option.item_selected.connect(_apply_filters)
	return option

func _style_input(input: LineEdit) -> void:
	input.add_theme_font_override("font", FONT_MEDIUM)
	input.add_theme_font_size_override("font_size", 12)
	input.add_theme_stylebox_override("normal", _box(COLOR_PANEL, COLOR_BORDER))
	input.add_theme_stylebox_override("focus", _box(COLOR_PANEL, Color("#71717a")))
	input.add_theme_color_override("font_color", COLOR_TEXT)
	input.add_theme_color_override("font_placeholder_color", Color("#71717a"))

## Library tabs: Puzzles | Cards, centered in the top bar (the current one is gold).
func _library_tabs(current: String) -> Control:
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	holder.add_child(row)
	for tab in [["Puzzles", "res://Scenes/ArchiveView.tscn"], ["Cards", "res://Scenes/CardsView.tscn"]]:
		var button := Button.new()
		button.text = tab[0]
		button.custom_minimum_size = Vector2(96, 30)
		button.add_theme_font_override("font", FONT_BOLD)
		button.add_theme_font_size_override("font_size", 14)
		var active: bool = tab[0] == current
		var box := StyleBoxFlat.new()
		box.bg_color = COLOR_GOLD if active else Color("#18181b")
		box.border_color = COLOR_GOLD if active else Color("#3f3f46")
		box.set_border_width_all(1)
		if tab[0] == "Puzzles":
			box.corner_radius_top_left = 6
			box.corner_radius_bottom_left = 6
		else:
			box.corner_radius_top_right = 6
			box.corner_radius_bottom_right = 6
		var hover := box.duplicate()
		if not active:
			hover.bg_color = Color("#27272a")
		for state in ["normal", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, box)
		button.add_theme_stylebox_override("hover", hover)
		var fg := Color("#18181b") if active else Color("#fafafa")
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, fg)
		if not active:
			button.pressed.connect(func(): get_tree().change_scene_to_file(tab[1]))
		row.add_child(button)
	return holder
