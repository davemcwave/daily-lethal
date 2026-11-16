extends Control
## Puzzle Archive (desktop): every released daily puzzle in one sortable, filterable table,
## like a server browser. (Today's daily is the main menu's Daily button.)
##
## Puzzles come from PuzzleArchive: the bundled list plus newer dailies fetched from
## playlethal.fun. Beaten puzzles are saved in Background (user://archive_progress.save).
const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const SKULL_TEXTURE: Texture2D = preload("res://Assets/Textures/white-skull.png")
const HOUSE_TEXTURE: Texture2D = preload("res://Assets/Textures/house-white.png")

const COLOR_PANEL := Color("#18181b")
const COLOR_BORDER := Color("#3f3f46")
const COLOR_TEXT := Color("#fafafa")
const COLOR_MUTED := Color("#a1a1aa")
const COLOR_GOLD := Color("#ffce4e")
const COLOR_BEATEN := Color("#36b24a")
const COLOR_SKULL := Color(0.83, 0.23, 0.25)
const COLOR_CUSTOM := Color("#c084fc")  # custom puzzles (made in the Card Lab or imported): purple
const DIFFICULTY_NAMES := ["Very Easy", "Easy", "Medium", "Hard", "Very Hard"]

enum Col { BEATEN, DATE, ENEMY, AUTHOR, DIFFICULTY, STATUS, CARDS, HP, ENERGY, ENEMY_HP }
const COLUMNS := [
	{"title": "", "width": 28, "expand": false},
	{"title": "Date", "width": 86, "expand": false},
	{"title": "Enemy", "width": 150, "expand": false},
	{"title": "Author", "width": 118, "expand": false},
	{"title": "Difficulty", "width": 80, "expand": false},
	{"title": "Status", "width": 66, "expand": false},
	{"title": "Cards", "width": 220, "expand": true},
	{"title": "HP", "width": 38, "expand": false},
	{"title": "Energy", "width": 52, "expand": false},
	{"title": "Enemy HP", "width": 66, "expand": false},
]

@onready var background = $"/root/Background"
@onready var audio_handler = $"/root/AudioHandler"

var puzzles: Array = []          # every puzzle (bundled, plus newer ones fetched online)
var shown: Array = []            # after filters, in table order
var sort_column: int = Col.DATE
var sort_descending: bool = true
var today: String = ""
var selected_cards: Array = []   # card filter: puzzles must have every one of these
var card_preview: Control        # the card shown beside the card filter's list while hovering
var preview_faces: Dictionary = {}  # card name -> its face (made once)

var tree: Tree
var search: LineEdit
var card_filter: Button
var card_list: PanelContainer     # the card filter's dropdown: a checkbox per card
var card_boxes: VBoxContainer
var difficulty_filter: OptionButton
var beaten_filter: OptionButton
var status_filter: OptionButton
var author_filter: OptionButton
var source_filter: OptionButton
var count_label: Label
var play_button: Button
var edit_button: Button    # custom puzzles only
var share_button: Button   # custom puzzles only
var delete_button: Button  # custom puzzles only

func _ready() -> void:
	background.leave_story_puzzle()
	background.leave_archive_puzzle()
	background.set_from_story_view(false)
	today = PuzzleArchive.today()
	puzzles = PuzzleArchive.load_bundled() + _custom_entries()
	selected_cards = background.archive_preset_cards.duplicate()
	background.archive_preset_cards = []
	_build_ui()
	if not background.library_notice.is_empty():
		source_filter.select(2)  # just imported: show the custom puzzles
	_refresh_card_filter()
	_apply_filters()
	LibraryImport.show_notice(self)
	if not background.library_import_code.is_empty():  # opened from a shared link (?import=)
		var code: String = background.library_import_code
		background.library_import_code = ""
		LibraryImport.open(self, "res://Scenes/ArchiveView.tscn", code)
	# Dailies released after this build: added when the website answers.
	if await PuzzleArchive.fetch_newer(self, puzzles) > 0:
		_refresh_card_filter()
		_apply_filters()

# ---------------------------------------------------------------- data

## The player's custom puzzles (CustomLibrary), as archive entries.
func _custom_entries() -> Array:
	var entries: Array = []
	for custom in CustomLibrary.puzzles():
		entries.append({"id": "custom:" + str(custom["id"]), "custom": true, "library_id": str(custom["id"]),
			"date": str(custom.get("added", "")), "enemy": str(custom.get("name", "Custom puzzle")),
			"author": str(custom.get("author", "")), "skulls": clampi(int(custom.get("difficulty", 0)), 0, 5), "cards": CustomLibrary.hand_names(custom),
			"php": int(custom.get("hp", 10)), "energy": int(custom.get("energy", 5)), "ehp": int(custom.get("enemy_hp", 20)),
			"statuses": [], "search": CustomLibrary.puzzle_search(custom)})
	return entries

func _is_beaten(entry: Dictionary) -> bool:
	return background.is_archive_puzzle_completed(str(entry.get("id", "")))

# ---------------------------------------------------------------- filters and table

## The card filter: a checklist of every card; ticked cards must all be in the puzzle.
## The author filter: every author, most puzzles first ("EulersApprentice (64)").
func _refresh_author_filter() -> void:
	var selected := _selected_author()
	var counts := {}
	for entry in puzzles:
		var author := str(entry.get("author", ""))
		if not author.is_empty():
			counts[author] = counts.get(author, 0) + 1
	var authors: Array = counts.keys()
	authors.sort_custom(func(a, b): return counts[a] > counts[b] if counts[a] != counts[b] else a.to_lower() < b.to_lower())
	author_filter.clear()
	author_filter.add_item("Any author")
	for author in authors:
		author_filter.add_item("%s (%d)" % [author, counts[author]])
		author_filter.set_item_metadata(author_filter.item_count - 1, author)
		if author == selected:
			author_filter.select(author_filter.item_count - 1)

func _selected_author() -> String:
	if author_filter == null or author_filter.selected <= 0:
		return ""
	return str(author_filter.get_item_metadata(author_filter.selected))

func _refresh_card_filter() -> void:
	_refresh_author_filter()
	var names := {}
	for entry in puzzles:
		for card in entry.get("cards", []):
			names[card] = true
	var sorted_names: Array = names.keys()
	sorted_names.sort()
	for child in card_boxes.get_children():
		child.queue_free()
	for card in sorted_names:
		var box := CheckBox.new()
		box.text = card
		box.button_pressed = card in selected_cards
		box.add_theme_font_override("font", FONT_MEDIUM)
		box.add_theme_font_size_override("font_size", 12)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			box.add_theme_color_override(state, COLOR_TEXT)
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color("#27272a")
		hover.set_corner_radius_all(4)
		box.add_theme_stylebox_override("hover", hover)
		box.add_theme_stylebox_override("hover_pressed", hover)
		box.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		box.add_theme_icon_override("checked", _checkbox_icon(true))
		box.add_theme_icon_override("unchecked", _checkbox_icon(false))
		box.toggled.connect(_on_card_toggled.bind(card))
		box.mouse_entered.connect(_show_card_preview.bind(card, box))
		card_boxes.add_child(box)
	_update_card_filter_label()

## A small rounded box: gold with a dark check when ticked, an outline when not (made once).
var _checkbox_icons: Dictionary = {}
func _checkbox_icon(checked: bool) -> ImageTexture:
	if _checkbox_icons.has(checked):
		return _checkbox_icons[checked]
	var n := 14
	var image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var corner := (x == 0 or x == n - 1) and (y == 0 or y == n - 1)
			if corner:
				continue
			var edge := x == 0 or y == 0 or x == n - 1 or y == n - 1
			if checked:
				image.set_pixel(x, y, COLOR_GOLD)
			elif edge:
				image.set_pixel(x, y, Color("#71717a"))
	if checked:
		for t in 16:
			var u := t / 15.0
			for p in [Vector2(3, 7).lerp(Vector2(5.5, 9.5), u), Vector2(5.5, 9.5).lerp(Vector2(10.5, 4), u)]:
				image.set_pixel(int(p.x), int(p.y), Color("#18181b"))
				image.set_pixel(int(p.x) + 1, int(p.y), Color("#18181b"))
	_checkbox_icons[checked] = ImageTexture.create_from_image(image)
	return _checkbox_icons[checked]

func _on_card_toggled(on: bool, card: String) -> void:
	if on and card not in selected_cards:
		selected_cards.append(card)
	elif not on:
		selected_cards.erase(card)
	_update_card_filter_label()
	_apply_filters()

## Opens or closes the card list under the card filter button.
func _toggle_card_list() -> void:
	if card_list.visible:
		_close_card_list()
		return
	card_list.position = Vector2(card_filter.global_position.x, card_filter.global_position.y + card_filter.size.y + 4)
	card_list.show()

func _close_card_list() -> void:
	card_list.hide()
	card_preview.hide()

## Clicking anywhere outside the card list closes it.
func _input(event: InputEvent) -> void:
	if card_list != null and card_list.visible and event is InputEventMouseButton and event.pressed:
		var inside_list := card_list.get_global_rect().has_point(event.position)
		var on_button := card_filter.get_global_rect().has_point(event.position)
		if not inside_list and not on_button:
			_close_card_list()

## The hovered card, shown beside the card list.
func _show_card_preview(card_name: String, row: Control) -> void:
	for child in card_preview.get_children():
		child.hide()
	if not preview_faces.has(card_name):
		var face := CardFaces.make_face(card_name)
		if face == null:  # a custom card
			for custom in CustomLibrary.cards():
				if str(custom["def"].get("name", "")) == card_name:
					face = CustomLibrary.make_face(custom["id"])
					break
		if face == null:
			card_preview.hide()
			return
		face.size = Vector2(120, 160)
		face.scale = Vector2(1.25, 1.25)
		face.position = Vector2.ZERO
		card_preview.add_child(face)
		preview_faces[card_name] = face
	preview_faces[card_name].show()
	var face_size := Vector2(120, 160) * 1.25
	var at := Vector2(card_list.position.x + card_list.size.x + 8, row.global_position.y + row.size.y / 2.0 - face_size.y / 2.0)
	if at.x + face_size.x > size.x:
		at.x = card_list.position.x - face_size.x - 8  # no room on the right: show it on the left
	at.y = clampf(at.y, 8.0, size.y - face_size.y - 8.0)
	card_preview.position = at
	card_preview.show()

func _update_card_filter_label() -> void:
	match selected_cards.size():
		0: card_filter.text = "Any card"
		1: card_filter.text = str(selected_cards[0])
		_: card_filter.text = "%s + %d more" % [selected_cards[0], selected_cards.size() - 1]

func _apply_filters(_value = null) -> void:
	var words: Array = Array(search.text.strip_edges().to_lower().split(" ", false))
	shown = []
	for entry in puzzles:
		# Search matches any field (every word has to appear somewhere).
		var haystack := _search_text(entry)
		if words.any(func(word): return not haystack.contains(word)):
			continue
		var cards: Array = entry.get("cards", [])
		if selected_cards.any(func(card): return card not in cards):
			continue
		if difficulty_filter.selected > 0 and int(entry.get("skulls", 3)) != difficulty_filter.selected:
			continue
		if source_filter.selected == 1 and entry.get("custom", false):
			continue
		if source_filter.selected == 2 and not entry.get("custom", false):
			continue
		if beaten_filter.selected == 1 and _is_beaten(entry):
			continue
		if beaten_filter.selected == 2 and not _is_beaten(entry):
			continue
		var author := _selected_author()
		if not author.is_empty() and str(entry.get("author", "")) != author:
			continue
		var statuses: Array = entry.get("statuses", [])
		match status_filter.selected:
			1:
				if not statuses.is_empty():
					continue
			2:
				if "Doom" not in statuses:
					continue
			3:
				if "Retaliate" not in statuses:
					continue
		shown.append(entry)
	shown.sort_custom(_compare)
	_fill_tree()

## Everything a row shows, for the search box.
func _search_text(entry: Dictionary) -> String:
	var parts: Array = [entry["date"], entry["enemy"], entry.get("author", ""), _cards_text(entry.get("cards", [])),
		", ".join(entry.get("statuses", [])), _difficulty_name(entry),
		"custom" if entry.get("custom", false) else "official", "hp %d" % int(entry.get("php", 0)), "energy %d" % int(entry.get("energy", 0)), "enemy hp %d" % int(entry.get("ehp", 0))]
	if _is_beaten(entry):
		parts.append("beaten")
	return " ".join(parts).to_lower()

func _sort_key(entry: Dictionary, column: int):
	match column:
		Col.BEATEN: return 1 if _is_beaten(entry) else 0
		Col.ENEMY: return str(entry["enemy"]).to_lower()
		Col.AUTHOR: return str(entry.get("author", "")).to_lower()
		Col.DIFFICULTY: return int(entry.get("skulls", 3))
		Col.STATUS: return ", ".join(entry.get("statuses", []))
		Col.CARDS: return (entry.get("cards", []) as Array).size()
		Col.HP: return int(entry.get("php", 0))
		Col.ENERGY: return int(entry.get("energy", 0))
		Col.ENEMY_HP: return int(entry.get("ehp", 0))
	return str(entry["date"])

func _compare(a: Dictionary, b: Dictionary) -> bool:
	var ka = _sort_key(a, sort_column)
	var kb = _sort_key(b, sort_column)
	if ka == kb:
		return str(a["date"]) > str(b["date"])  # ties: newest first
	return ka > kb if sort_descending else ka < kb

func _fill_tree() -> void:
	tree.clear()
	var root := tree.create_item()
	for entry in shown:
		var item := tree.create_item(root)
		item.set_metadata(0, entry)
		item.set_cell_mode(Col.BEATEN, TreeItem.CELL_MODE_CUSTOM)
		item.set_custom_draw_callback(Col.BEATEN, _draw_beaten)
		item.set_text(Col.DATE, str(entry["date"]))
		var enemy := str(entry["enemy"])
		var statuses: Array = entry.get("statuses", [])
		item.set_text(Col.STATUS, ", ".join(statuses))
		item.set_custom_color(Col.STATUS, Color("#f0b14a"))
		var custom: bool = entry.get("custom", false)
		if str(entry["date"]) == today and not custom:
			enemy += "  TODAY"
		item.set_text(Col.ENEMY, enemy)
		if custom:
			# Custom puzzles: CUSTOM in purple where the date goes, the name in purple too.
			item.set_text(Col.DATE, "CUSTOM")
		item.set_text(Col.AUTHOR, str(entry.get("author", "")))
		item.set_cell_mode(Col.DIFFICULTY, TreeItem.CELL_MODE_CUSTOM)
		item.set_custom_draw_callback(Col.DIFFICULTY, _draw_skulls)
		item.set_text(Col.CARDS, _cards_text(entry.get("cards", [])))
		item.set_text(Col.HP, str(int(entry.get("php", 0))))
		item.set_text(Col.ENERGY, str(int(entry.get("energy", 0))))
		item.set_text(Col.ENEMY_HP, str(int(entry.get("ehp", 0))))
		for column in [Col.HP, Col.ENERGY, Col.ENEMY_HP]:
			item.set_text_alignment(column, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_custom_color(Col.DATE, COLOR_CUSTOM if custom else COLOR_MUTED)
		item.set_custom_color(Col.AUTHOR, COLOR_MUTED)
		if custom:
			item.set_custom_font(Col.DATE, FONT_BOLD)
			item.set_custom_color(Col.ENEMY, COLOR_CUSTOM)
			for column in COLUMNS.size():
				item.set_custom_bg_color(column, Color(COLOR_CUSTOM, 0.07))
		elif str(entry["date"]) == today:
			for column in COLUMNS.size():
				item.set_custom_bg_color(column, Color(COLOR_GOLD, 0.12))
			item.set_custom_color(Col.ENEMY, COLOR_GOLD)
	for column in COLUMNS.size():
		var title: String = COLUMNS[column]["title"]
		if column == sort_column and not title.is_empty():
			title += "  v" if sort_descending else "  ^"
		tree.set_column_title(column, title)
	count_label.text = "Showing %d of %d puzzles" % [shown.size(), puzzles.size()]
	_on_selection_changed()

func _difficulty_name(entry: Dictionary) -> String:
	if entry.get("custom", false) and int(entry.get("skulls", 0)) == 0:
		return "No difficulty set"
	return DIFFICULTY_NAMES[clampi(int(entry.get("skulls", 3)), 1, 5) - 1]

func _selected_entry() -> Dictionary:
	var item := tree.get_selected() if tree != null else null
	return item.get_metadata(0) if item != null else {}

## PLAY needs a row; Share code and Delete show for a custom puzzle.
func _on_selection_changed() -> void:
	var entry := _selected_entry()
	play_button.disabled = entry.is_empty()
	var custom: bool = entry.get("custom", false)
	edit_button.visible = custom and background.card_lab_available()
	share_button.visible = custom
	delete_button.visible = custom
	_arm_delete(delete_button, false)

## Opens the selected custom puzzle (and its cards) in the Puzzle Lab, in place of what's there.
func _edit_selected() -> void:
	var entry := _selected_entry()
	if not entry.get("custom", false):
		return
	var lab := ShareCode.decode(CustomLibrary.share_code([], [entry["library_id"]]))
	if lab.has("error"):
		return
	background.card_lab_incoming_puzzle = lab
	get_tree().change_scene_to_file(background.CARD_BUILDER_SCENE)

## Copies a share code with the selected custom puzzle and its cards.
func _share_selected() -> void:
	var entry := _selected_entry()
	if not entry.get("custom", false):
		return
	DisplayServer.clipboard_set(ShareCode.chat_code(CustomLibrary.share_code([], [entry["library_id"]])))
	share_button.text = "Code copied"
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(share_button):
			share_button.text = "Share code")

## Deletes the selected custom puzzle (the button asks once more first). Its cards stay.
func _delete_selected() -> void:
	var entry := _selected_entry()
	if not entry.get("custom", false):
		return
	if delete_button.text != "Delete?":
		_arm_delete(delete_button, true)
		return
	CustomLibrary.remove_puzzle(entry["library_id"])
	puzzles.erase(entry)
	_refresh_card_filter()
	_apply_filters()

## "Echo, Slash, Wound x2": each card once, with a count for duplicates.
func _cards_text(cards: Array) -> String:
	var counts := {}
	var order: Array = []
	for card in cards:
		if not counts.has(card):
			counts[card] = 0
			order.append(card)
		counts[card] += 1
	var parts: Array = []
	for card in order:
		parts.append(card if counts[card] == 1 else "%s x%d" % [card, counts[card]])
	return ", ".join(parts)

func _draw_skulls(item: TreeItem, rect: Rect2) -> void:
	if item.get_metadata(0).get("custom", false) and int(item.get_metadata(0).get("skulls", 0)) == 0:
		return
	var skulls := clampi(int(item.get_metadata(0).get("skulls", 3)), 1, 5)
	var size_px := 12.0
	var x := rect.position.x + 6.0
	for s in skulls:
		tree.draw_texture_rect(SKULL_TEXTURE, Rect2(Vector2(x + s * (size_px + 1.0), rect.get_center().y - size_px / 2.0), Vector2(size_px, size_px)), false, COLOR_SKULL)

func _draw_beaten(item: TreeItem, rect: Rect2) -> void:
	if not _is_beaten(item.get_metadata(0)):
		return
	var center := rect.get_center()
	tree.draw_circle(center, 7.0, COLOR_BEATEN, true, -1.0, true)
	tree.draw_polyline(PackedVector2Array([center + Vector2(-3.5, 0), center + Vector2(-1, 2.5), center + Vector2(3.5, -2.5)]), Color.WHITE, 1.8, true)

func _on_column_title_clicked(column: int, _mouse_button: int) -> void:
	if column == sort_column:
		sort_descending = not sort_descending
	else:
		sort_column = column
		sort_descending = column in [Col.DATE, Col.BEATEN]
	_apply_filters()

func _clear_filters() -> void:
	search.text = ""
	selected_cards.clear()
	_refresh_card_filter()
	for option in [difficulty_filter, beaten_filter, status_filter, author_filter, source_filter]:
		option.select(0)
	_apply_filters()

# ---------------------------------------------------------------- playing

func _play(entry: Dictionary) -> void:
	audio_handler.play_sfx("DrawSFX")
	background.archive_queue = shown.duplicate()
	background.start_archive_puzzle(entry)

func _play_selected() -> void:
	var item := tree.get_selected()
	if item != null:
		_play(item.get_metadata(0))

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

	# Top bar: Main Menu and the title.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	var menu := _button("MAIN MENU", false)
	menu.icon = HOUSE_TEXTURE
	menu.expand_icon = false
	menu.add_theme_constant_override("icon_max_width", 14)
	menu.pressed.connect(func():
		if OS.has_feature("web"):
			background.open_site_home()  # the web build has no main menu
		else:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn"))
	top.add_child(menu)
	top.add_child(_library_tabs("Puzzles"))
	# Both sides of the tabs the same width, so the tabs stay centered.
	var side_width := 230.0
	var pad := Control.new()
	pad.custom_minimum_size.x = side_width - menu.get_combined_minimum_size().x
	top.add_child(pad)
	top.move_child(pad, menu.get_index() + 1)
	var right := HBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.custom_minimum_size.x = side_width
	right.add_child(LibraryImport.button(self, "res://Scenes/ArchiveView.tscn"))
	top.add_child(right)

	# Filters.
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
	card_filter = Button.new()
	card_filter.add_theme_font_override("font", FONT_MEDIUM)
	card_filter.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		card_filter.add_theme_stylebox_override(state, _box(COLOR_PANEL if state != "hover" else Color("#27272a"), COLOR_BORDER))
	card_filter.add_theme_color_override("font_color", COLOR_TEXT)
	card_filter.add_theme_color_override("font_hover_color", COLOR_TEXT)
	card_filter.custom_minimum_size = Vector2(110, 0)
	card_filter.pressed.connect(_toggle_card_list)
	# The card list (tick any number of cards; hovering a name shows the card beside it).
	card_list = PanelContainer.new()
	card_list.z_index = 40
	card_list.custom_minimum_size = Vector2(190, 360)
	card_list.add_theme_stylebox_override("panel", _box(Color("#18181b"), COLOR_BORDER))
	card_list.mouse_exited.connect(func():
		if not card_list.get_global_rect().has_point(get_viewport().get_mouse_position()):
			card_preview.hide())
	card_list.hide()
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_list.add_child(list_scroll)
	card_boxes = VBoxContainer.new()
	card_boxes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_boxes.add_theme_constant_override("separation", 0)
	list_scroll.add_child(card_boxes)
	add_child(card_list)
	card_preview = Control.new()
	card_preview.z_index = 50
	card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.hide()
	add_child(card_preview)
	filters.add_child(card_filter)
	difficulty_filter = _option(["Any difficulty", "1 skull: Very Easy", "2 skulls: Easy", "3 skulls: Medium", "4 skulls: Hard", "5 skulls: Very Hard"])
	filters.add_child(difficulty_filter)
	beaten_filter = _option(["All puzzles", "Not beaten", "Beaten"])
	filters.add_child(beaten_filter)
	status_filter = _option(["Any enemy", "No enemy status", "Doom", "Retaliate"])
	filters.add_child(status_filter)
	author_filter = _option(["Any author"])
	author_filter.custom_minimum_size = Vector2(110, 0)
	author_filter.clip_text = true
	filters.add_child(author_filter)
	source_filter = _option(["All sources", "Official", "Custom"])
	filters.add_child(source_filter)
	var clear := _button("Clear", false)
	clear.pressed.connect(_clear_filters)
	filters.add_child(clear)

	# The table.
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.columns = COLUMNS.size()
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.set("auto_tooltip", false)  # no hover text in the Library (not even a cut-off cell's text)
	for i in COLUMNS.size():
		tree.set_column_custom_minimum_width(i, COLUMNS[i]["width"])
		tree.set_column_expand(i, COLUMNS[i]["expand"])
		tree.set_column_clip_content(i, true)
	_style_tree(tree)
	tree.column_title_clicked.connect(_on_column_title_clicked)
	tree.item_activated.connect(_play_selected)
	tree.item_selected.connect(_on_selection_changed)
	column.add_child(tree)

	# Footer.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)
	count_label = _label("", FONT_MEDIUM, 12, COLOR_MUTED)
	footer.add_child(count_label)
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	edit_button = _button("Edit in Puzzle Lab", false)
	edit_button.pressed.connect(_edit_selected)
	footer.add_child(edit_button)
	share_button = _button("Share code", false)
	share_button.pressed.connect(_share_selected)
	footer.add_child(share_button)
	delete_button = _button("Delete", false)
	delete_button.pressed.connect(_delete_selected)
	footer.add_child(delete_button)
	play_button = _button("PLAY", true)
	play_button.custom_minimum_size = Vector2(90, 0)
	play_button.disabled = true
	play_button.pressed.connect(_play_selected)
	footer.add_child(play_button)

func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

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
	button.add_theme_stylebox_override("disabled", _box(Color(bg, 0.4), COLOR_BORDER))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, fg)
	button.add_theme_color_override("font_disabled_color", Color(fg, 0.5))
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
		option.add_item(text)
	option.add_theme_font_override("font", FONT_MEDIUM)
	option.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		option.add_theme_stylebox_override(state, _box(COLOR_PANEL if state != "hover" else Color("#27272a"), COLOR_BORDER))
	option.add_theme_color_override("font_color", COLOR_TEXT)
	option.add_theme_color_override("font_hover_color", COLOR_TEXT)
	option.item_selected.connect(_apply_filters)
	return option

func _style_input(input: LineEdit) -> void:
	input.add_theme_font_override("font", FONT_MEDIUM)
	input.add_theme_font_size_override("font_size", 12)
	input.add_theme_stylebox_override("normal", _box(COLOR_PANEL, COLOR_BORDER))
	input.add_theme_stylebox_override("focus", _box(COLOR_PANEL, Color("#71717a")))
	input.add_theme_color_override("font_color", COLOR_TEXT)
	input.add_theme_color_override("font_placeholder_color", Color("#71717a"))

func _style_tree(t: Tree) -> void:
	var panel := _box(Color("#111113"), COLOR_BORDER)
	panel.content_margin_left = 0
	panel.content_margin_right = 0
	panel.content_margin_top = 0
	panel.content_margin_bottom = 0
	t.add_theme_stylebox_override("panel", panel)
	t.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var title := StyleBoxFlat.new()
	title.bg_color = COLOR_PANEL
	title.content_margin_left = 6
	title.content_margin_top = 4
	title.content_margin_bottom = 4
	for state in ["title_button_normal", "title_button_hover", "title_button_pressed"]:
		var box := title.duplicate()
		if state == "title_button_hover":
			box.bg_color = Color("#27272a")
		t.add_theme_stylebox_override(state, box)
	var selected := StyleBoxFlat.new()
	selected.bg_color = Color("#3f3f46")
	t.add_theme_stylebox_override("selected", selected)
	t.add_theme_stylebox_override("selected_focus", selected)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#1f1f23")
	t.add_theme_stylebox_override("hovered", hover)
	t.add_theme_font_override("font", FONT_MEDIUM)
	t.add_theme_font_override("title_button_font", FONT_BOLD)
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_font_size_override("title_button_font_size", 12)
	t.add_theme_color_override("font_color", COLOR_TEXT)
	t.add_theme_color_override("font_selected_color", COLOR_TEXT)
	t.add_theme_color_override("title_button_color", COLOR_MUTED)
	t.add_theme_color_override("guide_color", Color(1, 1, 1, 0.04))
	t.add_theme_constant_override("draw_guides", 1)
	t.add_theme_constant_override("v_separation", 6)
	t.add_theme_constant_override("h_separation", 4)
	t.add_theme_constant_override("item_margin", 0)

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
