extends Control
## In-game Card Builder: make a card from any registered effect, see it live,
## and try it in a test puzzle.
##
##   C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . res://Scenes/Builder/CardBuilder.tscn
##
## Everything is generated from EffectRegistry, so new effect scenes appear here
## automatically. The card is a CardFactory definition (the Card Lab's JSON format).

const PREVIEW_SCENE := "res://CardPreview.tscn"
const GAME_SCENE := "res://Scenes/Scene0Desktop.tscn"
const MAIN_MENU_SCENE := "res://Scenes/MainMenu.tscn"
const FONT_PATH := "res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf"
const FONT_BOLD_PATH := "res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf"

# Simple neutral palette (shadcn-style dark).
const C_BG := Color("#09090b")
const C_CARD := Color("#18181b")
## The two big page panels: see-through, so the background pattern shows behind them.
const C_PAGE_PANEL := Color(0.094, 0.094, 0.106, 0.7)
const C_BORDER := Color("#27272a")
const C_INPUT := Color("#0f0f12")
const C_TEXT := Color("#fafafa")
const C_MUTED := Color("#a1a1aa")
const C_PRIMARY := Color("#fafafa")
const C_PRIMARY_TEXT := Color("#18181b")
const C_ACCENT := Color("#3f3f46")
const C_DANGER := Color("#dc2626")
## The card colors, by what a card of that color does (the built-in cards' colors,
## as in the web Card Lab's CUSTOM_CARD_COLORS in puzzle-lab/index.html, minus Sky
## Blue, which no card uses).
const SWATCHES := [
	{"hex": "#8C0127", "name": "Damage", "meaning": "Cards that deal damage."},
	{"hex": "#C35400", "name": "Empower", "meaning": "Cards that buff damage, directly or through statuses like Vulnerable."},
	{"hex": "#8C008C", "name": "Utility", "meaning": "Cards that replay cards, add cards to your hand (including from the discard), or trash cards."},
	{"hex": "#008C10", "name": "Defense", "meaning": "Defensive cards, like healing or preventing damage."},
	{"hex": "#002A8C", "name": "Energy", "meaning": "Cards that gain energy, reduce costs, or make cards Free."},
]
const LABEL_WIDTH := 110
const CARD_SIDE_WIDTH := 360
const CARD_LABEL_WIDTH := 84
const PREVIEW_SCALE := 1.4
const TABS := ["Effects", "Test hand", "Data"]
## Settings the Card Lab sets itself instead of showing: a buff's target follows the
## buff (EffectRegistry.get_buff_target), since buffs go on the player except Corrode.
const HIDDEN_PARAMS := ["buff_auto_target"]
## Cards dealt next to the custom card in a new builder session's test puzzle.
const DEFAULT_OTHER_CARDS := ["res://Scenes/SlashCard.tscn", "res://Scenes/EchoCard.tscn"]

var definition: Dictionary = {}
## Every custom card in the test puzzle; `definition` is the one being edited
## (cards[current_card]). hand: the test puzzle's hand, in order.
const MAX_CARDS := ShareCode.MAX_CUSTOM_CARDS
const HAND_CARD_SCALE := 0.9  # the hand's cards, next to the 120 x 160 card art
const HAND_SLOT_PAD := 3.0  # room for the outline and the "×" around each card
const HAND_SLOT_SIZE := Vector2(120, 160) * HAND_CARD_SCALE + Vector2(HAND_SLOT_PAD, HAND_SLOT_PAD) * 2
var cards: Array = []
var current_card := 0
var card_tabs: HBoxContainer  # a tab per custom card, across the top of the editor
var show_advanced := false
## Which tab and which effect panel are open; static so they survive a test puzzle trip.
static var _current_tab := 0
## The Data tab (the card as raw data) is for power users: hidden until "Show
## card data" at the bottom of the Effects tab. Everything else is editable
## without it, nested effects included.
const DATA_TAB := 2
const TEST_TAB := 1  # its own tab in the strip, not part of a card
static var _show_card_data := false
static var _open_effect := 0
var copy_button: Button

var library_button: Button
var puzzle_name_edit: LineEdit  # the test puzzle's name, for sharing and the Library
var author_edit: LineEdit       # "Your name": the author of your cards and puzzles
var difficulty_pick: OptionButton  # the puzzle's difficulty: 0 not set, 1-5 skulls
var import_layer: Control = null
var icon_button: Button  # the card's icon; opens the icon picker
var icon_layer: Control = null  # the icon picker, while it's open
var card_menu: PopupMenu = null  # right-click on a card's chip
var import_edit: TextEdit
var import_status: Label
var share_status: Label
var tab_bar: HBoxContainer
var tab_bar_holder: Control       # the Effects | Data switch; only shown with the card data
var body: HBoxContainer            # the open card: its face and fields, and its effects
var test_panel: PanelContainer     # the Test puzzle tab's page (full width, instead of body)
var card_strip: Control           # the card tabs (only on Custom Cards)
var cards_mode_button: Button      # the two main tabs: Custom Cards | Custom Puzzle
var puzzles_mode_button: Button
 # the Test puzzle tab, at the right end of the tab strip

var name_edit: LineEdit
var energy_edit: LineEdit
var rules_edit: TextEdit
var color_hex_edit: LineEdit
var color_picker: ColorPickerButton
var swatch_buttons: Array[Button] = []
## "2 colors": a left-to-right blend of the card color and second_color.
var two_colors_check: CheckBox
var second_color_row: Control
var second_swatch_buttons: Array[Button] = []
var second_color := Color(SWATCHES[1]["hex"])
var effects_box: VBoxContainer
var effect_picker: OptionButton
var preview: Control
var preview_card: Card = null
var json_edit: TextEdit
var json_status: Label
var test_hp: LineEdit
var test_energy: LineEdit
var test_enemy_hp: LineEdit
var hand_title: Label
var hand_slots: HFlowContainer  # one card per card in the test hand, then "+"
var hand_picker: PopupMenu  # what the "+" slot adds: your cards, then built-in ones
var _hand_choices: Array = []  # hand_picker id -> int (your card) or String (built-in scene)
## Built-in cards dealt next to the custom card in the test puzzle (scene paths).
## The test hand, in the order it's dealt: an int is one copy of cards[int],
## a String a built-in card's scene path. Every custom card is in it at least once.
var hand: Array = []
var _updating := false


func _ready() -> void:
	var background = get_node_or_null("/root/Background")
	if background != null and not background.card_builder_cards.is_empty():
		cards = background.card_builder_cards.duplicate(true)
		current_card = clampi(background.card_builder_current, 0, cards.size() - 1)
		definition = cards[current_card]
	elif background != null and not background.card_builder_definition.is_empty():
		definition = background.card_builder_definition.duplicate(true)
	elif not _load_saved_lab(background):
		definition = _starter_definition()
	if cards.is_empty():
		cards = [definition]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tab="):  # dev: open on a tab (0 Effects, 1 Test hand, 2 Data)
			_current_tab = clampi(arg.trim_prefix("--tab=").to_int(), 0, TABS.size() - 1)
			_show_card_data = _show_card_data or _current_tab == DATA_TAB
		if arg.begins_with("--card-json="):  # dev: open with a card from a JSON file
			var loaded = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--card-json=")))
			if loaded is Dictionary:
				definition = loaded
				cards = [definition]
				current_card = 0
	theme = _make_theme()
	_build_layout()
	_load_definition_into_ui()
	_refresh()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--try-cards="):  # dev: e.g. --try-cards=Slash,Echo
			hand = hand.filter(func(entry): return entry is int)
			for card_name in arg.trim_prefix("--try-cards=").split(",", false):
				hand.append("res://Scenes/%sCard.tscn" % card_name.strip_edges().capitalize())
			_rebuild_hand()
	_take_incoming(background)
	_take_incoming_puzzle(background)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--import-code="):  # dev: open the import box with a code pasted in
			_open_import()
			import_edit.text = arg.trim_prefix("--import-code=")
			if "--import-now" in OS.get_cmdline_user_args():
				_on_import()
	if "--open-card-menu" in OS.get_cmdline_user_args():  # dev: the right-click menu on the first card
		(func(): _open_card_menu(0)).call_deferred()
	if "--open-hand-picker" in OS.get_cmdline_user_args():  # dev: the hand's "+" menu
		get_tree().create_timer(0.5).timeout.connect(func(): _open_hand_picker(hand_slots.get_child(hand_slots.get_child_count() - 1)))
	if "--open-icons" in OS.get_cmdline_user_args():  # dev: open the icon picker
		_open_icon_picker.call_deferred()
	if "--try-now" in OS.get_cmdline_user_args():
		_on_try_it.call_deferred()  # dev: jump straight into the test puzzle


func _starter_definition() -> Dictionary:
	return {
		"format": CardFactory.FORMAT,
		"name": "My Card",
		"energy": 1,
		"description": "Deal {{effect0.damage_amount}} damage.",
		"description_template": "Deal {{effect0.damage_amount}} damage.",
		"color": SWATCHES[0]["hex"],
		"effects": [{"type": "Damage", "params": {"damage_amount": 3}}],
	}


# ---------------------------------------------------------------- layout

## The game screen's tiled pattern (Scene0 / Scene0Desktop "BGRepeat"): bg.png
## tiled at about a tenth of its size. Stronger than the game's 8% because the
## Card Lab's near-black background and panels swallow it.
const BG_PATTERN_PATH := "res://bg.png"
const BG_PATTERN_SCALE := 0.105193
const BG_PATTERN_ALPHA := 0.18

func _add_background_pattern() -> void:
	var pattern := TextureRect.new()
	pattern.texture = load(BG_PATTERN_PATH)
	pattern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pattern.stretch_mode = TextureRect.STRETCH_TILE
	pattern.scale = Vector2.ONE * BG_PATTERN_SCALE
	pattern.self_modulate = Color(1, 1, 1, BG_PATTERN_ALPHA)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pattern)
	# Scaled down, so it has to be that much bigger to cover the screen.
	var fit := func(): pattern.size = size / BG_PATTERN_SCALE
	resized.connect(fit)
	fit.call()

func _build_layout() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _box(C_BG, Color.TRANSPARENT, 0, 0))
	add_child(bg)
	_add_background_pattern()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)

	# Top bar: back, title, and the actions you want from anywhere.
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	page.add_child(top_bar)
	top_bar.add_child(_button("‹  Main menu", _on_main_menu))
	# A thin divider with room on both sides keeps the back button apart from the title.
	var divider_holder := MarginContainer.new()
	divider_holder.add_theme_constant_override("margin_left", 8)
	divider_holder.add_theme_constant_override("margin_right", 8)
	divider_holder.add_theme_constant_override("margin_top", 6)
	divider_holder.add_theme_constant_override("margin_bottom", 6)
	var divider := ColorRect.new()
	divider.color = C_BORDER
	divider.custom_minimum_size = Vector2(1, 0)
	divider_holder.add_child(divider)
	top_bar.add_child(divider_holder)
	var title := _label("Puzzle Lab", 18, C_TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	top_bar.add_child(_button("Go to Library", _on_go_to_library))
	library_button = _button("Save to Library", _on_save_to_library)
	library_button.tooltip_text = "Save your cards and this test puzzle to your Library (Library > Puzzles and Cards, marked Custom)"
	top_bar.add_child(library_button)
	var play_button := _button("Play test  ›", _on_try_it, true)
	play_button.custom_minimum_size = Vector2(120, 0)
	top_bar.add_child(play_button)

	# The two main tabs: Custom Cards (a tab per card below) and Custom Puzzle (the test puzzle).
	var mode_bg := PanelContainer.new()
	mode_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mode_bg.add_theme_stylebox_override("panel", _box(C_BG, C_BORDER, 6, 2))
	page.add_child(mode_bg)
	var mode_bar := HBoxContainer.new()
	mode_bar.add_theme_constant_override("separation", 2)
	mode_bg.add_child(mode_bar)
	var mode_group := ButtonGroup.new()
	cards_mode_button = _tab_button("Custom Cards", mode_group)
	cards_mode_button.custom_minimum_size.x = 130
	cards_mode_button.pressed.connect(func(): _open_card(current_card))
	mode_bar.add_child(cards_mode_button)
	puzzles_mode_button = _tab_button("Custom Puzzle", mode_group)
	puzzles_mode_button.custom_minimum_size.x = 130
	puzzles_mode_button.pressed.connect(func(): _show_tab(TEST_TAB))
	mode_bar.add_child(puzzles_mode_button)

	# Which custom card you're editing: a tab per card (each with its own "×"), then "+".
	var strip := PanelContainer.new()
	card_strip = strip
	var line := StyleBoxFlat.new()
	line.bg_color = Color(0, 0, 0, 0)
	line.border_color = C_BORDER
	line.border_width_bottom = 1
	strip.add_theme_stylebox_override("panel", line)
	page.add_child(strip)
	var strip_scroll := ScrollContainer.new()
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.add_child(strip_scroll)
	card_tabs = HBoxContainer.new()
	card_tabs.add_theme_constant_override("separation", 2)
	strip_scroll.add_child(card_tabs)
	strip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.remove_child(strip_scroll)
	var strip_row := HBoxContainer.new()
	strip.add_child(strip_row)
	strip_row.add_child(strip_scroll)

	body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	test_panel = PanelContainer.new()
	test_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	test_panel.add_theme_stylebox_override("panel", _box(C_PAGE_PANEL, C_BORDER, 8, 10))
	page.add_child(test_panel)
	_build_card_side(body)
	_build_tabs(body)
	_apply_view()

## Left: the card, big, with its own fields right under it.
func _build_card_side(parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_SIDE_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", _box(C_PAGE_PANEL, C_BORDER, 8, 10))
	parent.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)

	var preview_holder := CenterContainer.new()
	box.add_child(preview_holder)
	var preview_frame := Control.new()
	preview_frame.custom_minimum_size = Vector2(120, 160) * PREVIEW_SCALE + Vector2(0, 6)
	preview_holder.add_child(preview_frame)
	preview = load(PREVIEW_SCENE).instantiate()
	preview.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	preview_frame.add_child(preview)

	name_edit = LineEdit.new()
	name_edit.text_changed.connect(func(_t): _on_card_field_changed())
	box.add_child(_row("Name", name_edit, CARD_LABEL_WIDTH))
	energy_edit = _number_edit(1, true, func(_v): _on_card_field_changed())
	box.add_child(_row("Energy", _with_steppers(energy_edit, true, 1), CARD_LABEL_WIDTH))
	box.add_child(_row("Color", _color_controls(), CARD_LABEL_WIDTH))
	# "[x] 2 colors" sits in the label column, so the second color's boxes line up
	# under the first color's; they show once it's checked.
	var two_colors_line := HBoxContainer.new()
	two_colors_line.add_theme_constant_override("separation", 8)
	two_colors_check = CheckBox.new()
	two_colors_check.text = "2 colors"
	two_colors_check.tooltip_text = "Blend two card colors left to right, like Haunt (Empower and Utility)."
	two_colors_check.custom_minimum_size = Vector2(CARD_LABEL_WIDTH, 0)
	two_colors_check.add_theme_font_size_override("font_size", 12)
	two_colors_check.toggled.connect(func(on):
		second_color_row.visible = on
		_on_card_field_changed())
	two_colors_line.add_child(two_colors_check)
	second_color_row = _swatch_row(second_swatch_buttons, func(color: Color):
		second_color = color
		_update_swatch_selection(second_swatch_buttons, color)
		_on_card_field_changed())
	second_color_row.visible = false
	two_colors_line.add_child(second_color_row)
	box.add_child(two_colors_line)
	icon_button = Button.new()
	icon_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_button.expand_icon = true
	icon_button.custom_minimum_size = Vector2(0, 34)
	icon_button.tooltip_text = "Choose the card's picture"
	icon_button.pressed.connect(_open_icon_picker)
	box.add_child(_row("Icon", icon_button, CARD_LABEL_WIDTH))
	# Description: label + live-value button on one line, a full-width wrapping box below.
	var description_header := HBoxContainer.new()
	var description_label := _label("Description", 12, C_MUTED)
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_header.add_child(description_label)
	description_header.add_child(_label("{ } next to a setting adds its live value", 10, C_MUTED))
	box.add_child(description_header)
	rules_edit = TextEdit.new()
	rules_edit.placeholder_text = "Deal {{effect0.damage_amount}} damage."
	rules_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	rules_edit.custom_minimum_size = Vector2(0, 74)
	rules_edit.scroll_fit_content_height = false
	rules_edit.text_changed.connect(_on_card_field_changed)
	box.add_child(rules_edit)

## Right: one group of settings at a time.
func _build_tabs(parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(C_PAGE_PANEL, C_BORDER, 8, 10))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 2)
	var tab_bg := PanelContainer.new()
	tab_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tab_bg.add_theme_stylebox_override("panel", _box(C_BG, C_BORDER, 6, 2))
	tab_bg.add_child(tab_bar)
	box.add_child(tab_bg)
	tab_bar_holder = tab_bg
	var pages := []
	var group := ButtonGroup.new()
	for tab_index in TABS.size():
		var page_scroll := ScrollContainer.new()
		page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var page_box := VBoxContainer.new()
		page_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_box.add_theme_constant_override("separation", 8)
		page_scroll.add_child(page_box)
		pages.append(page_scroll)
		if tab_index == TEST_TAB:
			# The test puzzle isn't part of a card: its own tab in the strip, its own page.
			test_panel.add_child(page_scroll)
			var placeholder := Button.new()  # keeps tab_bar's child indexes matching TABS
			placeholder.visible = false
			tab_bar.add_child(placeholder)
			_build_test_page(page_box)
			continue
		box.add_child(page_scroll)
		var tab := _tab_button(TABS[tab_index], group)
		tab_bar.add_child(tab)
		tab.toggled.connect(func(on):
			page_scroll.visible = on
			if on:
				_current_tab = tab_index)
		match tab_index:
			0: _build_effects_page(page_box)
			1: _build_test_page(page_box)
			2: _build_data_page(page_box)
	if _current_tab == DATA_TAB and not _show_card_data:
		_current_tab = 0
	tab_bar.get_child(DATA_TAB).visible = _show_card_data
	tab_bar_holder.visible = _show_card_data
	var card_page := _current_tab if _current_tab != TEST_TAB else 0
	for tab_index in TABS.size():
		if tab_index != TEST_TAB:
			pages[tab_index].visible = tab_index == card_page
	var keep := _current_tab
	tab_bar.get_child(card_page).button_pressed = true
	_current_tab = keep  # pressing the button above sets it; the Test puzzle tab may be the one open

## Opens a page: the Test puzzle tab, or a page of the open card (Effects, Data).
func _show_tab(tab_index: int) -> void:
	if tab_index == TEST_TAB:
		_current_tab = TEST_TAB
	else:
		tab_bar.get_child(tab_index).button_pressed = true  # the group switches the pages
		_current_tab = tab_index
	_apply_view()
	_rebuild_card_tabs()

## The Test puzzle tab shows its page in place of the card's.
func _apply_view() -> void:
	if body == null or test_panel == null:
		return
	body.visible = _current_tab != TEST_TAB
	test_panel.visible = _current_tab == TEST_TAB
	if _current_tab == TEST_TAB and _hand_dirty:
		_rebuild_hand()
	card_strip.visible = _current_tab != TEST_TAB
	cards_mode_button.set_pressed_no_signal(_current_tab != TEST_TAB)
	puzzles_mode_button.set_pressed_no_signal(_current_tab == TEST_TAB)

func _tab_button(text: String, group: ButtonGroup) -> Button:
	var tab := Button.new()
	tab.text = text
	tab.toggle_mode = true
	tab.button_group = group
	tab.custom_minimum_size = Vector2(96, 0)
	tab.add_theme_stylebox_override("normal", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 4))
	tab.add_theme_stylebox_override("hover", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 4))
	tab.add_theme_stylebox_override("pressed", _box(C_ACCENT, Color.TRANSPARENT, 4, 4))
	tab.add_theme_stylebox_override("hover_pressed", _box(C_ACCENT, Color.TRANSPARENT, 4, 4))
	tab.add_theme_color_override("font_color", C_MUTED)
	tab.add_theme_color_override("font_hover_color", C_TEXT)
	tab.add_theme_color_override("font_pressed_color", C_TEXT)
	tab.add_theme_color_override("font_hover_pressed_color", C_TEXT)
	return tab

func _build_effects_page(page_box: VBoxContainer) -> void:
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	page_box.add_child(add_row)
	effect_picker = OptionButton.new()
	effect_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Effects built-in cards use (proven by the puzzle tests), plus/minus the Card
	# Lab's own extras and hidden ones (EffectRegistry.CARD_LAB_*_EFFECTS).
	var offered := EffectRegistry.get_card_lab_effect_ids()
	for id in offered:
		effect_picker.add_item(_effect_title(id))
		effect_picker.set_item_metadata(effect_picker.item_count - 1, id)
	effect_picker.select(maxi(offered.find("Damage"), 0))
	add_row.add_child(effect_picker)
	add_row.add_child(_button("+  Add effect", _on_add_effect, true))
	effects_box = VBoxContainer.new()
	effects_box.add_theme_constant_override("separation", 6)
	page_box.add_child(effects_box)
	var data_toggle := Button.new()
	data_toggle.flat = true
	data_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	data_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	data_toggle.add_theme_color_override("font_color", C_MUTED)
	data_toggle.add_theme_font_size_override("font_size", 11)
	data_toggle.text = "Hide card data" if _show_card_data else "Show card data"
	data_toggle.tooltip_text = "The card as raw data, for copying or editing by hand"
	data_toggle.pressed.connect(func():
		_show_card_data = not _show_card_data
		data_toggle.text = "Hide card data" if _show_card_data else "Show card data"
		tab_bar.get_child(DATA_TAB).visible = _show_card_data
		tab_bar_holder.visible = _show_card_data
		_show_tab(DATA_TAB if _show_card_data else 0))
	page_box.add_child(data_toggle)

func _build_test_page(page_box: VBoxContainer) -> void:
	share_status = _label("", 12, Color("#4ade80"))
	share_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	share_status.visible = false
	page_box.add_child(share_status)
	puzzle_name_edit = LineEdit.new()
	puzzle_name_edit.placeholder_text = "Training Dummy"
	puzzle_name_edit.max_length = ShareCode.MAX_TEXT
	puzzle_name_edit.text_changed.connect(func(_t): _save_try_settings())
	page_box.add_child(_row("Puzzle name", puzzle_name_edit, 110))
	author_edit = LineEdit.new()
	author_edit.placeholder_text = "Your name, shown on your cards and puzzles"
	author_edit.max_length = ShareCode.MAX_TEXT
	author_edit.text_changed.connect(func(_t): _save_try_settings())
	page_box.add_child(_row("Author", author_edit, 110))
	difficulty_pick = OptionButton.new()
	for label in ["Not set", "1 skull: Very Easy", "2 skulls: Easy", "3 skulls: Medium", "4 skulls: Hard", "5 skulls: Very Hard"]:
		difficulty_pick.add_item(label)
	difficulty_pick.item_selected.connect(func(_i): _save_try_settings())
	page_box.add_child(_row("Difficulty", difficulty_pick, 110))
	test_hp = _number_edit(10, true, func(_v): _save_try_settings())
	test_energy = _number_edit(5, true, func(_v): _save_try_settings())
	test_enemy_hp = _number_edit(20, true, func(_v): _save_try_settings())
	page_box.add_child(_row("Player HP", _with_steppers(test_hp, true, 1), 110))
	page_box.add_child(_row("Player energy", _with_steppers(test_energy, true, 1), 110))
	page_box.add_child(_row("Enemy HP", _with_steppers(test_enemy_hp, true, 1), 110))
	hand_title = _label("Hand", 12, C_MUTED)
	page_box.add_child(hand_title)
	hand_slots = HFlowContainer.new()
	hand_slots.add_theme_constant_override("h_separation", 6)
	hand_slots.add_theme_constant_override("v_separation", 6)
	hand_slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_box.add_child(hand_slots)
	hand_picker = PopupMenu.new()
	hand_picker.id_pressed.connect(_on_hand_pick)
	add_child(hand_picker)
	_load_try_settings()

func _build_data_page(page_box: VBoxContainer) -> void:
	page_box.add_child(_hint("The card as data. Edit it and press Apply, or paste a card in."))
	json_edit = TextEdit.new()
	json_edit.custom_minimum_size = Vector2(0, 220)
	json_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	json_edit.add_theme_font_size_override("font_size", 11)
	json_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	page_box.add_child(json_edit)
	var json_row := HBoxContainer.new()
	json_row.add_theme_constant_override("separation", 6)
	page_box.add_child(json_row)
	json_row.add_child(_button("Apply", _on_apply_json, true))
	copy_button = _button("Copy card data", _on_copy_json)
	json_row.add_child(copy_button)
	json_status = _label("", 11, C_MUTED)
	json_row.add_child(json_status)


func _section(parent: Container, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(C_CARD, C_BORDER, 8, 10))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_label(title, 14, C_TEXT, true))
	return box

## A "Label  [control]" row with a fixed-width label.
func _row(label_text: String, control: Control, label_width := LABEL_WIDTH) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := _label(label_text, 12, C_MUTED)
	label.custom_minimum_size = Vector2(label_width, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row

func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", load(FONT_BOLD_PATH))
	return label

## Small muted text that wraps to the width it's given.
func _hint(text: String) -> Label:
	var label := _label(text, 11, C_MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String, on_pressed: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	if primary:
		button.add_theme_stylebox_override("normal", _box(C_PRIMARY, C_PRIMARY, 6, 6))
		button.add_theme_stylebox_override("hover", _box(C_PRIMARY.darkened(0.12), C_PRIMARY, 6, 6))
		button.add_theme_stylebox_override("pressed", _box(C_PRIMARY.darkened(0.2), C_PRIMARY, 6, 6))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, C_PRIMARY_TEXT)
	return button

## A plain text input for numbers; on_change gets the parsed number.
func _number_edit(value: float, is_int: bool, on_change: Callable) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = str(int(value)) if is_int else str(value)
	edit.custom_minimum_size = Vector2(48, 0)
	edit.text_changed.connect(func(t: String):
		if t.is_valid_int() or (not is_int and t.is_valid_float()):
			on_change.call(t.to_int() if is_int else t.to_float()))
	return edit

## Number input with small - / + buttons.
func _with_steppers(edit: LineEdit, is_int: bool, step: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(edit)
	for delta in [-step, step]:
		var stepper := _button("−" if delta < 0 else "+", func():
			var current: float = edit.text.to_float() if edit.text.is_valid_float() else 0.0
			var next: float = current + float(delta)
			edit.text = str(int(next)) if is_int else str(snappedf(next, 0.01))
			edit.text_changed.emit(edit.text))
		stepper.custom_minimum_size = Vector2(28, 0)
		row.add_child(stepper)
	return row

func _color_controls() -> HBoxContainer:
	var row := _swatch_row(swatch_buttons, _set_card_color)
	color_hex_edit = LineEdit.new()
	color_hex_edit.custom_minimum_size = Vector2(64, 0)
	color_hex_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_hex_edit.text_submitted.connect(func(t): if Color.html_is_valid(t): _set_card_color(Color.html(t)))
	row.add_child(color_hex_edit)
	color_picker = ColorPickerButton.new()
	color_picker.custom_minimum_size = Vector2(28, 22)
	color_picker.tooltip_text = "Custom color"
	color_picker.color_changed.connect(func(c): _set_card_color(c))
	row.add_child(color_picker)
	return row

## One box per card color; on_pick gets the Color. The boxes go in `buttons`.
func _swatch_row(buttons: Array[Button], on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for swatch_color: Dictionary in SWATCHES:
		var hex: String = swatch_color["hex"]
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(24, 22)
		swatch.tooltip_text = "%s\n%s" % [swatch_color["name"], swatch_color["meaning"]]
		swatch.add_theme_stylebox_override("normal", _box(Color(hex), C_BORDER, 4, 0))
		swatch.add_theme_stylebox_override("hover", _box(Color(hex), C_MUTED, 4, 0))
		swatch.add_theme_stylebox_override("pressed", _box(Color(hex), C_TEXT, 4, 0))
		swatch.set_meta("hex", hex)
		swatch.pressed.connect(func(): on_pick.call(Color(hex)))
		buttons.append(swatch)
		row.add_child(swatch)
	return row

func _box(fill: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding + 2
	box.content_margin_right = padding + 2
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

## An empty square outline, visible on the dark background (unchecked box).
func _outline_box_icon(size: int, color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for i in range(2, size - 2):
		for edge in [2, size - 3]:
			image.set_pixel(i, edge, color)
			image.set_pixel(edge, i, color)
	return ImageTexture.create_from_image(image)

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = load(FONT_PATH)
	t.default_font_size = 13
	var input := _box(C_INPUT, C_BORDER, 6, 4)
	var input_focus := _box(C_INPUT, C_MUTED, 6, 4)
	for type in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", type, input)
		t.set_stylebox("focus", type, input_focus)
		t.set_stylebox("read_only", type, input)
		t.set_color("font_color", type, C_TEXT)
		t.set_color("font_placeholder_color", type, C_MUTED)
		t.set_color("caret_color", type, C_TEXT)
	for type in ["Button", "OptionButton", "ColorPickerButton"]:
		t.set_stylebox("normal", type, _box(C_CARD, C_BORDER, 6, 4))
		t.set_stylebox("hover", type, _box(C_ACCENT, C_BORDER, 6, 4))
		t.set_stylebox("pressed", type, _box(C_ACCENT, C_MUTED, 6, 4))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, C_TEXT)
		t.set_color("font_hover_color", type, C_TEXT)
		t.set_color("font_pressed_color", type, C_TEXT)
		t.set_color("font_focus_color", type, C_TEXT)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	t.set_icon("unchecked", "CheckBox", _outline_box_icon(16, C_MUTED))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(state, "CheckBox", C_TEXT)
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("panel", "PopupMenu", _box(C_CARD, C_BORDER, 6, 4))
	t.set_stylebox("hover", "PopupMenu", _box(C_ACCENT, Color.TRANSPARENT, 4, 2))
	t.set_color("font_color", "PopupMenu", C_TEXT)
	t.set_color("font_hover_color", "PopupMenu", C_TEXT)
	t.set_constant("v_separation", "PopupMenu", 4)
	return t


# ---------------------------------------------------------------- effects UI

func _rebuild_effects_ui() -> void:
	for child in effects_box.get_children():
		child.queue_free()
	var effects: Array = definition.get("effects", [])
	if effects.is_empty():
		effects_box.add_child(_hint("No effects yet. Pick one above and press Add effect."))
	for i in effects.size():
		effects_box.add_child(_effect_panel(effects, i, ""))

## Effects inside effects. "children": a Condition's "Then" (it runs only the
## first one); an effect-list setting (Player Choose Effect's choices) gets its
## own list. Each nested effect is edited with the same panel as a card's own.
const CHILD_LIST_TYPES := {"Condition": {"title": "Then", "limit": 1}}
const MAX_NESTING := 4
## Which nested effect is open, per list: "<list key>" -> index. Top-level
## effects use _open_effect.
static var _open_nested := {}

## One effect: a one-line summary ("Buff: Sharp 3") that opens to its settings.
## One panel per list is open at a time, so several effects still fit on screen.
## list_key is "" for the card's own effects, else the path to the nested list
## ("0/children", "0/card_effects_to_choose_from/1/children", ...).
func _effect_panel(list: Array, index: int, list_key: String) -> Control:
	var effect: Dictionary = list[index]
	var top_level := list_key.is_empty()
	var is_open: bool = index == _open_effect if top_level else _open_nested.get(list_key, -1) == index
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(C_BG, C_MUTED.darkened(0.4) if is_open else C_BORDER, 6, 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	box.add_child(title_row)
	var header := Button.new()
	header.flat = true
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.text = "%s   %s" % ["−" if is_open else "+", _effect_summary(effect)]
	header.tooltip_text = "Close" if is_open else "Open settings"
	header.add_theme_font_override("font", load(FONT_BOLD_PATH))
	header.pressed.connect(func():
		if top_level:
			_open_effect = -1 if is_open else index
		elif is_open:
			_open_nested.erase(list_key)
		else:
			_open_nested[list_key] = index
		_rebuild_effects_ui())
	title_row.add_child(header)
	if index > 0:
		var up := _button("Up", func(): _move_effect(list, list_key, index, -1))
		up.tooltip_text = "Move up (effects run top to bottom)"
		title_row.add_child(up)
	var duplicate := _button("Copy", func(): _duplicate_effect(list, list_key, index))
	duplicate.tooltip_text = "Duplicate (adds a copy right below)"
	title_row.add_child(duplicate)
	var remove := _button("×", func(): _remove_effect(list, list_key, index))
	remove.tooltip_text = "Remove"
	title_row.add_child(remove)
	if not is_open:
		return panel

	var type: String = effect.get("type", "")
	if not EffectRegistry.has_effect(type):
		box.add_child(_hint("Unknown effect type; it can only be edited as card data."))
		return panel
	var params: Dictionary = effect.get("params", {})
	var effect_key := ("%d" % index) if top_level else "%s/%d" % [list_key, index]
	var shown := 0
	var nested_params: Array[Dictionary] = []
	for info: Dictionary in EffectRegistry.get_params(type):
		var param_name: String = info["name"]
		if info["kind"] == EffectRegistry.KIND_EFFECTS:
			nested_params.append(info)
			continue
		if info.get("advanced", false) and not show_advanced:
			continue
		if param_name in HIDDEN_PARAMS:
			continue
		var value = params.get(param_name, info["default"])
		if info["kind"] == EffectRegistry.KIND_DICT:
			if param_name == "buff_params":
				shown += _add_buff_settings(box, effect, index if top_level else -1, value)
			continue
		var editor := _param_editor(info, value, func(v): _set_param(effect, param_name, v))
		if editor == null:
			continue
		# Live values ({{effect0.damage_amount}}) only reach the card's own effects.
		if top_level and info["kind"] != EffectRegistry.KIND_COLOR:
			editor = _with_live_button(editor, _live_value_button("{{effect%d.%s}}" % [index, param_name]))
		box.add_child(_row(_setting_label(param_name), editor, 150))
		shown += 1
	var nesting := effect_key.count("/") / 2
	for info in nested_params:
		var param_name: String = info["name"]
		if not effect.has("params"):
			effect["params"] = {}
		box.add_child(_nested_effects_ui(effect["params"], param_name, _nested_title(param_name), 0, effect_key + "/" + param_name, nesting))
		shown += 1
	if CHILD_LIST_TYPES.has(type) or effect.has("children"):
		var child_list: Dictionary = CHILD_LIST_TYPES.get(type, {"title": "Inner effects", "limit": 0})
		box.add_child(_nested_effects_ui(effect, "children", child_list["title"], child_list["limit"], effect_key + "/children", nesting))
		shown += 1
	if shown == 0:
		box.add_child(_hint("No settings."))
	var more := Button.new()
	more.flat = true
	more.alignment = HORIZONTAL_ALIGNMENT_LEFT
	more.text = "Fewer settings" if show_advanced else "More settings"
	more.add_theme_color_override("font_color", C_MUTED)
	more.add_theme_font_size_override("font_size", 11)
	more.pressed.connect(func():
		show_advanced = not show_advanced
		_rebuild_effects_ui())
	box.add_child(more)
	return panel

## "card_effects_to_choose_from" -> "Choices"; other effect lists by their name.
func _nested_title(param_name: String) -> String:
	if param_name == "card_effects_to_choose_from":
		return "Choices"
	return _setting_label(param_name)

## A titled, indented list of effects held by an effect (holder[key]), with its
## own Add row. limit: how many it can hold (0 = any).
##   Then
##     | + Damage 3                     Copy  ×
##     | [Damage            v] [Add]
func _nested_effects_ui(holder: Dictionary, key: String, title: String, limit: int, list_key: String, nesting: int) -> Control:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	outer.add_child(_label(title, 12, C_TEXT, true))
	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", 14)
	outer.add_child(indent)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 4)
	indent.add_child(list_box)
	if not (holder.get(key) is Array):
		holder.erase(key)
	var list: Array = holder.get(key, [])
	for i in list.size():
		if list[i] is Dictionary:
			list_box.add_child(_effect_panel(list, i, list_key))
	if nesting >= MAX_NESTING:
		list_box.add_child(_hint("Effects can't go any deeper."))
		return outer
	if limit > 0 and list.size() >= limit:
		return outer
	if list.is_empty():
		list_box.add_child(_hint("Nothing yet. Add the effect it runs." if limit == 1 else "None yet."))
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 4)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in EffectRegistry.get_card_lab_effect_ids():
		picker.add_item(_effect_title(id))
		picker.set_item_metadata(picker.item_count - 1, id)
		if id == "Damage":
			picker.select(picker.item_count - 1)
	add_row.add_child(picker)
	add_row.add_child(_button("Add", func():
		if picker.selected < 0:
			return
		if not (holder.get(key) is Array):
			holder[key] = []
		holder[key].append(_new_effect(picker.get_item_metadata(picker.selected)))
		_open_nested[list_key] = holder[key].size() - 1  # open the new effect
		_rebuild_effects_ui()
		_refresh()))
	list_box.add_child(add_row)
	return outer

## "CreateCard" -> "Create Card", "PlayerChooseEffect" -> "Player Choose Effect",
## "FreeBuff" -> "Free Status".
func _effect_title(id: String) -> String:
	return _status_word(id.capitalize())

## Players call buffs "statuses" (some go on the enemy: Corrode, Retaliate). Only
## the words shown change; the data keeps "Buff", and "Debuff" stays.
static func _status_word(text: String) -> String:
	var whole_word := RegEx.create_from_string("\\bBuff\\b")
	return whole_word.sub(text, "Status", true)

## "Buff: Sharp 3", "Damage 3", "Create Card: Slash": the type plus the
## settings this card changed, for a closed effect panel.
func _effect_summary(effect: Dictionary) -> String:
	var type: String = str(effect.get("type", "?"))
	if not EffectRegistry.has_effect(type):
		return type
	var params: Dictionary = effect.get("params", {})
	var parts: Array[String] = []
	for info: Dictionary in EffectRegistry.get_params(type):
		var param_name: String = info["name"]
		if info.get("advanced", false) or not params.has(param_name):
			continue
		var value = params[param_name]
		match info["kind"]:
			EffectRegistry.KIND_RESOURCE:
				parts.append(str(value).get_file().get_basename().trim_suffix("Debuff").trim_suffix("Buff").trim_suffix("Card").capitalize())
			EffectRegistry.KIND_INT, EffectRegistry.KIND_FLOAT:
				var number := str(int(value)) if info["kind"] == EffectRegistry.KIND_INT else str(value)
				parts.append(_labeled_number(type, param_name, number))
			EffectRegistry.KIND_DICT:
				# A buff's own settings follow the buff's name: "Sharp 3".
				for setting in (value as Dictionary if value is Dictionary else {}):
					if value[setting] is float or value[setting] is int:
						parts.append(str(int(value[setting])))
	var summary := _effect_title(type)
	if parts.is_empty():
		return summary
	var details := " ".join(parts.slice(0, 3))
	# "Damage 3" reads better than "Damage: 3" when the number is the effect's own amount.
	var reads_on := details.is_valid_int() or details.begins_with("up to ")
	return summary + (" " if reads_on else ": ") + details

## A number with its setting's name, unless the name just repeats the effect's:
## Damage's damage_amount -> "3", Discard's max_discard_amount -> "Max Discard 1".
## Generic words (amount, count, stacks, additional) are dropped, and "max"
## becomes "up to": Discard's max_discard_amount 1 -> "up to 1".
func _labeled_number(type: String, param_name: String, number: String) -> String:
	return EffectRegistry.labeled_number(type, param_name, number)

## The "{ }" at the end of a setting: adds that setting's live value
## ({{effect0.damage_amount}}, {{effect0.buff_scene}} -> "Sharp") to the description
## at the cursor, so the card text follows the setting even when buffs change it.
func _live_value_button(token: String, before_insert := Callable()) -> Button:
	var button := _button("{ }", func(): pass)
	button.custom_minimum_size = Vector2(30, 0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "Add this setting's live value to the description:\n" + token
	button.pressed.connect(func():
		if before_insert.is_valid():
			before_insert.call()
		rules_edit.insert_text_at_caret(token)
		_on_card_field_changed()
		button.text = "Added"
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(button):
				button.text = "{ }"))
	return button

## Puts the { } button at the end of a setting's row (after any - / + steppers).
func _with_live_button(editor: Control, live_button: Button) -> Control:
	if editor is HBoxContainer:
		editor.add_child(live_button)
		return editor
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(editor)
	row.add_child(live_button)
	return row

## "card_to_create_scene" -> "Card To Create", "buff_scene" -> "Status".
func _setting_label(param_name: String) -> String:
	return _status_word(EffectRegistry.setting_label(param_name))

## The chosen buff's own settings (Sharp's "Sharp Count", Regen's "Heal Amount",
## ...), stored in the effect's buff_params. Returns how many rows it added.
func _add_buff_settings(box: VBoxContainer, effect: Dictionary, index: int, buff_params) -> int:
	var params: Dictionary = effect.get("params", {})
	var buff_value: String = str(params.get("buff_scene", ""))
	if buff_value.is_empty():
		return 0
	var buff_path := EffectRegistry.allowed_scene_path("buff_scene", buff_value)
	if buff_path.is_empty():
		return 0
	var settings: Dictionary = buff_params if buff_params is Dictionary else {}
	var shown := 0
	for info: Dictionary in EffectRegistry.get_scene_params(buff_path):
		if info.get("advanced", false) and not show_advanced:
			continue
		var setting: String = info["name"]
		var current = settings.get(setting, info["default"])
		var editor := _param_editor(info, current, func(v): _set_buff_setting(effect, setting, v))
		if editor == null:
			continue
		if index >= 0 and info["kind"] != EffectRegistry.KIND_COLOR:
			# buff_params only holds changed settings; store this one so the token always resolves.
			editor = _with_live_button(editor, _live_value_button("{{effect%d.buff_params.%s}}" % [index, setting], func():
				var stored = effect.get("params", {}).get("buff_params", {})
				if not (stored is Dictionary and stored.has(setting)):
					_set_buff_setting(effect, setting, current)))
		box.add_child(_row("  " + _setting_label(setting), editor, 150))
		shown += 1
	return shown

func _param_editor(info: Dictionary, value, on_change: Callable) -> Control:
	match info["kind"]:
		EffectRegistry.KIND_INT, EffectRegistry.KIND_FLOAT:
			var is_int: bool = info["kind"] == EffectRegistry.KIND_INT
			var edit := _number_edit(float(value) if value != null else 0.0, is_int, on_change)
			return _with_steppers(edit, is_int, 1.0 if is_int else 0.1)
		EffectRegistry.KIND_BOOL:
			var check := CheckBox.new()
			check.button_pressed = bool(value)
			check.toggled.connect(on_change)
			return check
		EffectRegistry.KIND_ENUM:
			var option := OptionButton.new()
			var options: Array = info.get("options", [])
			for o in options:
				option.add_item(str(o))
			var uses_index: bool = info["default"] is int or info["default"] is float
			var selected: int = int(value) if uses_index else options.find(str(value))
			option.select(clampi(selected, 0, maxi(options.size() - 1, 0)))
			option.item_selected.connect(func(i): on_change.call(i if uses_index else options[i]))
			return option
		EffectRegistry.KIND_RESOURCE:
			# Always a pick list (the registry only offers scene settings that have one).
			# Buffs: only those some card gives (not enemy-only abilities or interfaces).
			var choices: Array = EffectRegistry.get_offered_buff_choices() if info["name"] == "buff_scene" \
				else EffectRegistry.get_resource_choices(info["name"])
			return _resource_picker(choices, str(value) if value != null else "", on_change)
		EffectRegistry.KIND_STRING:
			var line := LineEdit.new()
			line.text = str(value) if value != null else ""
			line.text_changed.connect(on_change)
			return line
		EffectRegistry.KIND_RESOURCES:
			return _resource_list_picker(EffectRegistry.get_resource_choices(info["name"]), value if value is Array else [], on_change,
				info["name"] == "card_scenes")
		EffectRegistry.KIND_COLOR:
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size = Vector2(0, 22)
			picker.color = Color.html(str(value)) if value != null else Color.WHITE
			picker.color_changed.connect(func(c): on_change.call("#" + c.to_html(true)))
			return picker
	return null  # nested effect lists have their own list (_nested_effects_ui)

## A dropdown of buffs / debuffs / cards by name. Changing it rebuilds the effect
## panels, since a different buff has different settings.
func _resource_picker(choices: Array, current: String, on_change: Callable) -> OptionButton:
	var option := OptionButton.new()
	option.add_item("Choose...")
	var selected := 0
	for i in choices.size():
		option.add_item(choices[i]["label"])
		if _is_choice(choices[i], current):
			selected = i + 1
	option.select(selected)
	option.item_selected.connect(func(i: int):
		if i >= 1 and i <= choices.size():
			on_change.call(choices[i - 1]["id"])  # card data stores the name, never a path
			_rebuild_effects_ui.call_deferred())
	return option

## Card data names a choice ("Sharp"); older data may hold its path.
func _is_choice(choice: Dictionary, value: String) -> bool:
	return value == choice["id"] or value == choice["path"]

## A list of cards (e.g. Pick To Create's options): removable chips plus a picker.
##   [Slash ×] [Spear ×]
##   [Pound          v] [Add]
func _resource_list_picker(choices: Array, current: Array, on_change: Callable, with_custom := false) -> Control:
	# Entries: a built-in card's id ("Slash"), or (with_custom, a list of cards) one of your
	# cards as its definition, kept up to date by _sync_embedded_cards.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	box.add_child(chips)
	var entries: Array = []
	for entry in current:
		if entry is Dictionary:
			if with_custom:
				entries.append(entry)
			continue
		for choice: Dictionary in choices:
			if _is_choice(choice, str(entry)):
				entries.append(choice["id"])
	for i in entries.size():
		var entry = entries[i]
		var label: String = ("%s (yours)" % entry.get("name", "Custom Card")) if entry is Dictionary else str(entry).capitalize()
		chips.add_child(_button(label + "  ×", func():
			var updated := entries.duplicate()
			updated.remove_at(i)
			on_change.call(updated)
			_rebuild_effects_ui.call_deferred()))
	if entries.is_empty():
		chips.add_child(_hint("None yet."))
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 4)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if with_custom and not cards.is_empty():
		picker.add_separator("Your cards")
		for i in cards.size():
			picker.add_item(str(cards[i].get("name", "Card %d" % (i + 1))))
			picker.set_item_metadata(picker.item_count - 1, {"custom": i})
		picker.add_separator("Built-in cards")
	for choice: Dictionary in choices:
		picker.add_item(choice["label"])
		picker.set_item_metadata(picker.item_count - 1, {"builtin": choice["id"]})
	for at in picker.item_count:  # start on the first card, not a heading
		if not picker.is_item_separator(at):
			picker.select(at)
			break
	add_row.add_child(picker)
	add_row.add_child(_button("Add", func():
		if picker.selected < 0 or picker.is_item_separator(picker.selected):
			return
		var pick: Dictionary = picker.get_item_metadata(picker.selected)
		var updated := entries.duplicate()
		if pick.has("custom"):
			cards[current_card] = definition
			updated.append(EffectRegistry.without_embedded_cards(cards[int(pick["custom"])]))
		else:
			updated.append(pick["builtin"])
		on_change.call(updated)
		_rebuild_effects_ui.call_deferred()))
	box.add_child(add_row)
	return box

## Your cards held inside other cards (Pick to Create's choices) follow your edits: each
## copy is replaced by the card with that name as it is now.
func _sync_embedded_cards() -> void:
	var latest := {}
	for card in cards:
		latest[str(card.get("name", ""))] = card
	for card in cards:
		_sync_effects(card.get("effects", []), latest)

func _sync_effects(effects, latest: Dictionary) -> void:
	for effect in (effects if effects is Array else []):
		if not effect is Dictionary:
			continue
		var params = effect.get("params", {})
		if params is Dictionary:
			for key in params:
				if not params[key] is Array:
					continue
				var list: Array = params[key]
				for at in list.size():
					var entry = list[at]
					if entry is Dictionary and entry.has("type"):
						_sync_effects([entry], latest)  # an effects list
					elif entry is Dictionary and latest.has(str(entry.get("name", ""))):
						list[at] = EffectRegistry.without_embedded_cards(latest[str(entry["name"])])
		_sync_effects(effect.get("children", []), latest)


# ---------------------------------------------------------------- editing

func _load_definition_into_ui() -> void:
	_updating = true
	name_edit.text = str(definition.get("name", ""))
	energy_edit.text = str(int(definition.get("energy", 1)))
	rules_edit.text = str(definition.get("description_template", definition.get("description", "")))
	var color := Color.html(str(definition.get("color", CardFactory.DEFAULT_COLOR)))
	color_hex_edit.text = "#" + color.to_html(false)
	color_picker.color = color
	_update_swatch_selection(swatch_buttons, color)
	# Two colors: "gradient": [color, second], or a Card Lab "colors" list.
	var stops: Array = definition["gradient"] if definition.get("gradient") is Array else definition.get("colors", [])
	var has_two: bool = stops is Array and stops.size() >= 2
	if has_two:
		second_color = Color.html(str(stops[-1]))
	two_colors_check.button_pressed = has_two
	second_color_row.visible = has_two
	_update_swatch_selection(second_swatch_buttons, second_color)
	_show_icon()
	_updating = false
	_rebuild_effects_ui()

## Outlines the swatch matching the card's color (none for a custom color).
func _update_swatch_selection(buttons: Array[Button], color: Color) -> void:
	for swatch in buttons:
		var hex: String = swatch.get_meta("hex")
		var selected := Color(hex).to_html(false) == color.to_html(false)
		var style := _box(Color(hex), C_TEXT if selected else C_BORDER, 4, 0)
		style.set_border_width_all(2 if selected else 1)
		swatch.add_theme_stylebox_override("normal", style)

func _set_card_color(color: Color) -> void:
	_updating = true
	color_hex_edit.text = "#" + color.to_html(false)
	color_picker.color = color
	_update_swatch_selection(swatch_buttons, color)
	_updating = false
	_on_card_field_changed()

func _on_card_field_changed() -> void:
	if _updating:
		return
	definition["name"] = name_edit.text
	if energy_edit.text.is_valid_int():
		definition["energy"] = energy_edit.text.to_int()
	definition["description"] = rules_edit.text
	if rules_edit.text.contains("{{"):
		definition["description_template"] = rules_edit.text
	else:
		definition.erase("description_template")
	definition["color"] = "#" + color_picker.color.to_html(true)
	definition.erase("colors")
	if two_colors_check.button_pressed:
		definition["gradient"] = [definition["color"], "#" + second_color.to_html(true)]
	else:
		definition.erase("gradient")
	_refresh()

func _on_add_effect() -> void:
	var type: String = effect_picker.get_item_metadata(effect_picker.selected)
	if not definition.has("effects"):
		definition["effects"] = []
	definition["effects"].append(_new_effect(type))
	_open_effect = definition["effects"].size() - 1  # open the new effect
	_rebuild_effects_ui()
	_refresh()

## A new effect of a type, with the Card Lab's starting settings.
func _new_effect(type: String) -> Dictionary:
	var new_effect := {"type": type}
	# A buff a card gives is otherwise used up by that same card's play (Sharp
	# triggers "on card play"), so new buff effects add theirs after the play, like
	# the old Card Lab did for Sharp. The checkbox shows it and can be unticked.
	for info: Dictionary in EffectRegistry.get_params(type):
		if info["name"] == "defer_add_until_after_card_play":
			new_effect["params"] = {"defer_add_until_after_card_play": true}
	return new_effect

## After a list's effects move: keeps its open panel on the same effect
## (renumber: old index -> new index, -1 = closed) and closes the nested lists
## under it, which are keyed by position.
func _reopen(list_key: String, renumber: Callable) -> void:
	if list_key.is_empty():
		if _open_effect >= 0:
			_open_effect = renumber.call(_open_effect)
	elif _open_nested.has(list_key):
		_open_nested[list_key] = renumber.call(_open_nested[list_key])
	var prefix := list_key + "/" if not list_key.is_empty() else ""
	for key: String in _open_nested.keys():
		if key != list_key and key.begins_with(prefix):
			_open_nested.erase(key)

## Inserts a copy of an effect (same settings) right below it, and opens the copy.
func _duplicate_effect(list: Array, list_key: String, index: int) -> void:
	list.insert(index + 1, list[index].duplicate(true))
	if list_key.is_empty():
		_renumber_description(func(i: int): return i + 1 if i > index else i)
	_reopen(list_key, func(_i): return index + 1)
	_rebuild_effects_ui()
	_refresh()

func _remove_effect(list: Array, list_key: String, index: int) -> void:
	list.remove_at(index)
	if list_key.is_empty():
		# References to the removed effect are left as they are (they'll show blank).
		_renumber_description(func(i: int): return i - 1 if i > index else i)
	_reopen(list_key, func(i: int): return -1 if i == index else (i - 1 if i > index else i))
	_rebuild_effects_ui()
	_refresh()

func _move_effect(list: Array, list_key: String, index: int, offset: int) -> void:
	var effect = list[index]
	list.remove_at(index)
	list.insert(index + offset, effect)
	var other := index + offset
	var swap := func(i: int): return other if i == index else (index if i == other else i)
	if list_key.is_empty():
		_renumber_description(swap)
	_reopen(list_key, swap)  # the open panel stays open as it moves
	_rebuild_effects_ui()
	_refresh()

## Keeps the description's {{effectN...}} references on the same effects after the
## list changes: renumber maps each old index to its new one.
func _renumber_description(renumber: Callable) -> void:
	var pattern := RegEx.create_from_string("\\{\\{(\\s*)effect(\\d+)")
	var text: String = rules_edit.text
	var result := ""
	var last := 0
	for found in pattern.search_all(text):
		result += text.substr(last, found.get_start() - last)
		result += "{{%seffect%d" % [found.get_string(1), renumber.call(found.get_string(2).to_int())]
		last = found.get_end()
	result += text.substr(last)
	if result != text:
		_updating = true
		rules_edit.text = result
		_updating = false
		_on_card_field_changed()

func _set_param(effect: Dictionary, param_name: String, value) -> void:
	if not effect.has("params"):
		effect["params"] = {}
	effect["params"][param_name] = value
	if param_name == "buff_scene":
		effect["params"].erase("buff_params")  # the old buff's settings don't apply
		# Who gets it comes from the buff: the player, except Corrode (the enemy).
		if EffectRegistry.get_buff_target(str(value)) == "Enemy":
			effect["params"]["buff_auto_target"] = "Enemy"
		else:
			effect["params"].erase("buff_auto_target")  # Player, the default
	_refresh()

func _set_buff_setting(effect: Dictionary, setting: String, value) -> void:
	if not effect.has("params"):
		effect["params"] = {}
	if not (effect["params"].get("buff_params") is Dictionary):
		effect["params"]["buff_params"] = {}
	effect["params"]["buff_params"][setting] = value
	_refresh()

func _on_apply_json() -> void:
	var parsed = JSON.parse_string(json_edit.text)
	if not (parsed is Dictionary):
		_set_json_status("That isn't valid card JSON.")
		return
	definition = parsed
	_load_definition_into_ui()
	_refresh()
	_set_json_status("Applied.")

func _set_json_status(text: String) -> void:
	json_status.text = text

func _on_copy_json() -> void:
	DisplayServer.clipboard_set(JSON.stringify(definition, "  ", false))
	copy_button.text = "Copied"
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(copy_button):
			copy_button.text = "Copy card data")


# ---------------------------------------------------------------- share codes

func _puzzle_name() -> String:
	var name := puzzle_name_edit.text.strip_edges()
	return name if not name.is_empty() else "Training Dummy"

## Your cards and the Test hand in ShareCode.decode_library's shape: each card with you
## as its author, and the Test hand as one named puzzle.
func _lab_as_library() -> Dictionary:
	_save_try_settings()
	cards[current_card] = definition
	_fit_hand()
	var author := author_edit.text.strip_edges()
	var puzzle_hand: Array = []
	for entry in hand:
		puzzle_hand.append(entry if entry is int else EffectRegistry.scene_name(entry))
	return {"cards": cards.map(func(card): return {"def": card, "author": author}),
			"puzzles": [{"name": _puzzle_name(), "author": author, "hp": _number_value(test_hp, 10),
						 "energy": _number_value(test_energy, 5), "enemy_hp": _number_value(test_enemy_hp, 20),
						 "difficulty": difficulty_pick.selected, "hand": puzzle_hand}]}

## Saves your cards and the Test hand (as a puzzle) to the Library.
## Cards or a puzzle with the same names already in the Library: ask before overwriting them.
func _on_save_to_library() -> void:
	var lab := _lab_as_library()
	var found := CustomLibrary.conflicts(lab, true)
	if found["cards"].is_empty() and found["puzzles"].is_empty():
		_save_to_library(lab)
		return
	var total: int = found["cards"].size() + found["puzzles"].size()
	_confirm("Overwrite %s?" % ("it" if total == 1 else "them"),
		"Your Library already has %s. Overwrite %s with this version, or cancel and rename yours." % [
			CustomLibrary.describe_conflicts(found), "it" if total == 1 else "them"],
		"Overwrite", func(): _save_to_library(lab))

func _save_to_library(lab: Dictionary) -> void:
	var result := CustomLibrary.save(lab, true)
	var parts: Array = []
	if result["puzzles"] > 0:
		parts.append("1 new puzzle")
	if result["replaced"] > 0:
		parts.append("puzzle overwritten")
	if result["cards"] > 0:
		parts.append(_count(result["cards"], "new card"))
	if result["updated"] > 0:
		parts.append(_count(result["updated"], "card") + " overwritten")
	library_button.text = "Saved" if not parts.is_empty() else "Already saved"
	share_status.visible = true
	share_status.text = ("Saved to your Library: %s. Share it from the Library, where it's marked Custom." % ", ".join(parts)) \
		if not parts.is_empty() else "Already in your Library, unchanged."
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(library_button):
			library_button.text = "Save to Library")

## A box over the page asking to confirm (the confirm button is red).
func _confirm(title: String, text: String, confirm_text: String, on_confirm: Callable) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 60
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			layer.queue_free())
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.add_theme_stylebox_override("panel", _box(C_CARD, C_BORDER, 8, 16))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_label(title, 16, C_TEXT, true))
	box.add_child(_hint(text))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(buttons)
	buttons.add_child(_button("Cancel", layer.queue_free))
	var confirm := _button(confirm_text, func():
		layer.queue_free()
		on_confirm.call())
	for state in ["normal", "hover", "pressed"]:
		confirm.add_theme_stylebox_override(state, _box(C_DANGER if state != "hover" else C_DANGER.lightened(0.1), C_DANGER, 6, 6))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		confirm.add_theme_color_override(state, Color.WHITE)
	buttons.add_child(confirm)

func _count(n: int, noun: String) -> String:
	return "%d %s%s" % [n, noun, "" if n == 1 else "s"]

## A box over the page to paste a code into, filled in from the clipboard when
## it already holds one.
func _open_import() -> void:
	if import_layer != null:
		return
	import_layer = Control.new()
	import_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(import_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_import())
	import_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	import_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", _box(C_CARD, C_BORDER, 8, 16))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label("Import a share code", 16, C_TEXT, true))
	box.add_child(_hint("Paste a share code. Save it to your Library (just the cards, or the cards and their puzzles; a puzzle always brings its cards), or open it here to edit."))
	import_edit = TextEdit.new()
	import_edit.custom_minimum_size = Vector2(0, 110)
	import_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	import_edit.add_theme_font_size_override("font_size", 11)
	import_edit.placeholder_text = ShareCode.PREFIX_V3 + "..."
	var clipboard := DisplayServer.clipboard_get().strip_edges()
	if clipboard.begins_with(ShareCode.PREFIX_V3) or clipboard.begins_with(ShareCode.PREFIX) or clipboard.begins_with(ShareCode.PREFIX_V1):
		import_edit.text = clipboard
	box.add_child(import_edit)
	import_status = _label("", 11, Color("#f87171"))
	import_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(import_status)
	box.add_child(_label("SAVE TO YOUR LIBRARY", 11, C_MUTED, true))
	var library_row := HBoxContainer.new()
	library_row.add_theme_constant_override("separation", 6)
	box.add_child(library_row)
	library_row.add_child(_button("Cards and puzzles", _on_import_library.bind(true), true))
	library_row.add_child(_button("Cards only", _on_import_library.bind(false)))
	box.add_child(_label("OPEN IN THE CARD LAB", 11, C_MUTED, true))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	buttons.add_child(_button("Add to my cards", _on_import_add))
	buttons.add_child(_button("Replace all", _on_import))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	buttons.add_child(_button("Cancel", _close_import))
	import_edit.grab_focus()

# ---------------------------------------------------------------- icon picker

const TEXTURES_DIR := "res://Assets/Textures/"
static var _icon_list: Array = []  # [{"path", "name"}]

## The icons a custom card can use: the built-in cards' icons.
func _icons() -> Array:
	if not _icon_list.is_empty():
		return _icon_list
	var seen := {}
	for choice in EffectRegistry.get_resource_choices("card"):
		var card := _builtin_card(choice["path"])
		var texture: Texture2D = card.get_icon_texture() if card != null else null
		if texture != null and not texture.resource_path.is_empty() and not seen.has(texture.resource_path):
			seen[texture.resource_path] = true
			_icon_list.append({"path": texture.resource_path, "name": texture.resource_path.get_file().get_basename()})
	_icon_list.sort_custom(func(a, b): return a["name"].naturalnocasecmp_to(b["name"]) < 0)
	return _icon_list

## The icon as card data keeps it: "sword" for a .png in Assets/Textures, else
## the path without "res://" (CardFactory reads both).
static func _icon_value(path: String) -> String:
	if path.begins_with(TEXTURES_DIR) and path.get_extension().to_lower() == "png" and not path.trim_prefix(TEXTURES_DIR).contains("/"):
		return path.get_file().get_basename()
	return path.trim_prefix("res://")

func _show_icon() -> void:
	if icon_button == null:
		return
	var value := str(definition.get("icon", ""))
	var texture: Texture2D = preview_card.get_icon_texture() if preview_card != null else null
	if not value.is_empty():
		var path := CardFactory.resolve_icon_path(value)
		if ResourceLoader.exists(path):
			texture = load(path)
	icon_button.icon = texture
	var shown_name := value.get_file().get_basename()
	if shown_name.is_empty() and texture != null:
		shown_name = texture.resource_path.get_file().get_basename()
	icon_button.text = "  %s   ›" % (shown_name if not shown_name.is_empty() else "Default")

func _set_icon(path: String) -> void:
	definition["icon"] = _icon_value(path)
	_refresh()
	_show_icon()
	_close_icon_picker()

## A box over the page with every card icon, each on the card's color so you
## see it as it would look.
func _open_icon_picker() -> void:
	if icon_layer != null:
		return
	icon_layer = Control.new()
	icon_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(icon_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_icon_picker())
	icon_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_layer.add_child(center)
	var panel := PanelContainer.new()
	var screen := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(minf(620, screen.x - 32), minf(440, screen.y - 40))
	panel.add_theme_stylebox_override("panel", _box(C_CARD, C_BORDER, 8, 14))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)
	var title := _label("Choose an icon", 16, C_TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("Close", _close_icon_picker))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	var color := Color.html(str(definition.get("color", CardFactory.DEFAULT_COLOR)))
	var current := ""
	if definition.has("icon"):
		current = CardFactory.resolve_icon_path(str(definition["icon"]))
	for icon in _icons():
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(56, 56)
		tile.expand_icon = true
		tile.icon = load(icon["path"])
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.tooltip_text = icon["name"]
		tile.focus_mode = Control.FOCUS_NONE
		var border := C_TEXT if icon["path"] == current else C_BORDER
		tile.add_theme_stylebox_override("normal", _box(color, border, 6, 6))
		tile.add_theme_stylebox_override("hover", _box(color.lightened(0.12), C_TEXT, 6, 6))
		tile.add_theme_stylebox_override("pressed", _box(color.lightened(0.2), C_TEXT, 6, 6))
		var path: String = icon["path"]
		tile.pressed.connect(func(): _set_icon(path))
		grid.add_child(tile)

func _close_icon_picker() -> void:
	if icon_layer != null:
		icon_layer.queue_free()
		icon_layer = null

## Adds a code's cards (and, with include_puzzles, its puzzles) to the Library.
func _on_import_library(include_puzzles: bool) -> void:
	var result := ShareCode.decode_library(import_edit.text)
	if result.has("error"):
		import_status.text = result["error"]
		return
	var added := CustomLibrary.save(result, include_puzzles)
	_close_import()
	share_status.visible = true
	_show_tab(1)
	share_status.text = "Added to your Library: %s%s. Find them in Library, marked Custom." % [
		_count(added["cards"], "new card"), (", " + _count(added["puzzles"], "new puzzle")) if include_puzzles else ""]

func _close_import() -> void:
	if import_layer != null:
		import_layer.queue_free()
		import_layer = null

## Adds the shared cards after yours (as many as there's room for), each in the
## hand as many times as the code has it. Your cards and Test hand settings stay.
## Cards the Library sent (Edit in Card Lab): open one already here, else add it (and deal it
## once in the Test hand) if there's room.
func _take_incoming(background) -> void:
	if background == null or background.card_lab_incoming.is_empty():
		return
	var incoming: Array = background.card_lab_incoming
	background.card_lab_incoming = []
	cards[current_card] = definition
	for def in incoming:
		if not def is Dictionary or def.is_empty():
			continue
		var key := JSON.stringify(def, "", true)
		var at := -1
		for i in cards.size():
			if JSON.stringify(cards[i], "", true) == key:
				at = i
		if at == -1:
			if cards.size() >= MAX_CARDS:
				share_status.visible = true
				share_status.text = "The Puzzle Lab holds %d cards. Remove one, then open the card from the Library again." % MAX_CARDS
				continue
			cards.append(def.duplicate(true))
			at = cards.size() - 1
			hand.append(at)
		_open_card(at)
	_save_try_settings()
	_rebuild_hand()

func _on_import_add() -> void:
	var result := ShareCode.decode(import_edit.text)
	if result.has("error"):
		import_status.text = result["error"]
		return
	var room := MAX_CARDS - cards.size()
	if room <= 0:
		import_status.text = "You have %d cards, the most the Puzzle Lab holds. Remove one first, or Replace all." % MAX_CARDS
		return
	cards[current_card] = definition
	var shared: Array = result["cards"]
	var copies: Array = result["puzzle"].get("card_copies", [])
	var added := mini(room, shared.size())
	for i in added:
		cards.append(shared[i])
		var count: int = int(copies[i]) if i < copies.size() else 1
		for n in maxi(1, count):
			hand.append(cards.size() - 1)
	_close_import()
	_select_card(cards.size() - added)
	_save_try_settings()
	_show_tab(1)  # Test hand: the new cards are on the end
	var names: Array = shared.slice(0, added).map(func(card): return "\"%s\"" % card.get("name", "Custom Card"))
	share_status.visible = true
	share_status.text = "Added %s." % ", ".join(names)
	if added < shared.size():
		share_status.text += " No room for %d more (the Puzzle Lab holds %d)." % [shared.size() - added, MAX_CARDS]

func _on_import() -> void:
	var result := ShareCode.decode(import_edit.text)
	if result.has("error"):
		import_status.text = result["error"]
		return
	_close_import()
	_replace_lab(result)
	if result.has("unknown_cards"):
		share_status.visible = true
		share_status.text = "Left out cards this version doesn't have: " + ", ".join(result["unknown_cards"])
	else:
		var what := "\"%s\"" % definition.get("name", "Custom Card") if cards.size() == 1 else "%d cards" % cards.size()
		share_status.visible = true
		share_status.text = "Imported %s. Press Play test to try it." % what

## A puzzle sent from the Library (Edit in Puzzle Lab). When the Lab has cards that aren't
## saved in the Library, asks before replacing them.
func _take_incoming_puzzle(background) -> void:
	if background == null or background.card_lab_incoming_puzzle.is_empty():
		return
	var incoming: Dictionary = background.card_lab_incoming_puzzle
	background.card_lab_incoming_puzzle = {}
	var title := str(incoming["puzzle"].get("name", "this puzzle"))
	var open_it := func():
		_replace_lab(incoming)
		share_status.visible = true
		share_status.text = "Opened \"%s\" from your Library. Save to Library again to keep your changes." % title
	var unsaved := _unsaved_lab_cards()
	if unsaved.is_empty():
		open_it.call()
		return
	var names: Array = unsaved.map(func(n): return "\"%s\"" % n)
	_confirm("Replace the Puzzle Lab?",
		"%s %s saved to your Library. Opening \"%s\" replaces everything in the Puzzle Lab." % [
			", ".join(names), "isn't" if names.size() == 1 else "aren't", title],
		"Replace", open_it)

## The Lab's cards that aren't in the Library as they are now (a fresh starter card doesn't count).
func _unsaved_lab_cards() -> Array:
	cards[current_card] = definition
	var starter := _starter_definition()
	var unsaved: Array = []
	for card in cards:
		var plain: Dictionary = card.duplicate(true)
		plain["name"] = starter.get("name", "")
		if JSON.stringify(plain, "", true) == JSON.stringify(starter, "", true):
			continue
		var saved := CustomLibrary.card_named(str(card.get("name", "")))
		if saved.is_empty() or JSON.stringify(saved["def"], "", true) != JSON.stringify(card, "", true):
			unsaved.append(str(card.get("name", "Custom Card")))
	return unsaved

## Puts a decoded share (ShareCode.decode's Lab shape: cards and one puzzle) in the Lab,
## in place of what's there, and opens its Custom Puzzle tab.
func _replace_lab(result: Dictionary) -> void:
	cards = result["cards"]
	current_card = 0
	definition = cards[0]
	_open_effect = 0
	_open_nested.clear()
	var puzzle: Dictionary = result["puzzle"]
	var background = get_node_or_null("/root/Background")
	if background != null:
		background.card_builder_try_settings = puzzle
	_load_try_settings()
	_load_definition_into_ui()
	_refresh()
	_save_try_settings()
	_show_tab(TEST_TAB)  # the Custom Puzzle tab: what came with it, next to Play test


# ---------------------------------------------------------------- preview & try

## Rebuilds the card from the definition, so the preview, the JSON and the
## stored definition always agree with what CardFactory makes.
func _refresh() -> void:
	if preview_card != null:
		preview_card.free()
		preview_card = null
	preview_card = CardFactory.create_card(definition)
	preview_card.update_description_panel()
	preview.set_card(preview_card)
	cards[current_card] = definition
	_sync_embedded_cards()
	json_edit.text = JSON.stringify(definition, "  ", false)
	_rebuild_card_tabs()
	# The hand is slow to rebuild (every card in it is made again): only when it's on screen,
	# else when the Custom Puzzle tab opens. Editing a card would lag otherwise (the web most).
	if _current_tab == TEST_TAB:
		_rebuild_hand()
	else:
		_hand_dirty = true
	var background = get_node_or_null("/root/Background")
	if background != null:
		background.card_builder_definition = definition.duplicate(true)
		background.card_builder_cards = cards.duplicate(true)
		background.card_builder_current = current_card

# ---------------------------------------------------------------- several cards

## The tabs across the top: one per custom card (the open one joined to the page below),
## each with its own "×" (first click: a red "Delete?", second click deletes; moving away
## cancels), then "+" for another card. Right-click a tab for its menu too.
func _rebuild_card_tabs() -> void:
	if card_tabs == null:
		return
	for child in card_tabs.get_children():
		child.queue_free()
	for i in cards.size():
		var open := i == current_card and _current_tab != TEST_TAB
		var card_name := str(cards[i].get("name", "Card %d" % (i + 1)))
		if card_name.length() > 16:
			card_name = card_name.left(15) + "…"
		var tab := PanelContainer.new()
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab.add_theme_stylebox_override("panel", _tab_box(open, false))
		if not open:
			tab.mouse_entered.connect(func(): tab.add_theme_stylebox_override("panel", _tab_box(false, true)))
			tab.mouse_exited.connect(func(): tab.add_theme_stylebox_override("panel", _tab_box(false, false)))
		tab.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					_open_card(i)
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					_open_card_menu(i))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tab.add_child(row)
		var title := Label.new()
		title.text = card_name
		title.add_theme_color_override("font_color", C_TEXT if open else C_MUTED)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(title)
		var remove := Button.new()
		remove.text = "×"
		remove.flat = true
		remove.focus_mode = Control.FOCUS_NONE
		remove.add_theme_color_override("font_color", C_MUTED)
		remove.add_theme_color_override("font_hover_color", C_TEXT)
		remove.pressed.connect(func():
			if remove.text == "×":
				remove.text = "Delete?"
				remove.flat = false
				for state in ["normal", "hover", "pressed"]:
					remove.add_theme_stylebox_override(state, _box(C_DANGER if state != "hover" else C_DANGER.lightened(0.1), C_DANGER, 4, 0))
				for state in ["font_color", "font_hover_color", "font_pressed_color"]:
					remove.add_theme_color_override(state, Color.WHITE)
			else:
				_remove_card(i))
		remove.mouse_exited.connect(func():
			if is_instance_valid(remove) and remove.text != "×":
				remove.text = "×"
				remove.flat = true
				for state in ["normal", "hover", "pressed"]:
					remove.remove_theme_stylebox_override(state)
				remove.add_theme_color_override("font_color", C_MUTED)
				remove.add_theme_color_override("font_hover_color", C_TEXT)
				remove.add_theme_color_override("font_pressed_color", C_TEXT))
		row.add_child(remove)
		card_tabs.add_child(tab)
	if cards.size() < MAX_CARDS:
		var add := Button.new()
		add.text = "+  New card"
		add.flat = true
		add.focus_mode = Control.FOCUS_NONE
		add.add_theme_color_override("font_color", C_MUTED)
		add.add_theme_color_override("font_hover_color", C_TEXT)
		add.pressed.connect(_add_card)
		card_tabs.add_child(add)

## Clicking a card's tab (or Custom Cards): that card, on its own page.
func _open_card(index: int) -> void:
	if _current_tab == TEST_TAB:
		_current_tab = 0
		_apply_view()
	if index == current_card:
		_rebuild_card_tabs()
	else:
		_select_card(index)

## A card tab's look: the open one is filled and joined to the page (no bottom edge).
func _tab_box(open: bool, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = C_CARD if open else (Color(C_CARD, 0.5) if hover else Color(0, 0, 0, 0))
	box.border_color = C_BORDER if open else Color(0, 0, 0, 0)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.content_margin_left = 12
	box.content_margin_right = 4
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	if open:
		box.expand_margin_bottom = 1  # covers the strip's line under it
	return box

func _select_card(index: int) -> void:
	if index == current_card or index < 0 or index >= cards.size():
		return
	cards[current_card] = definition
	current_card = index
	definition = cards[index]
	_open_effect = 0
	_open_nested.clear()
	_load_definition_into_ui()
	_refresh()

func _add_card() -> void:
	if _current_tab == TEST_TAB:
		_current_tab = 0
		_apply_view()
	cards[current_card] = definition
	var new_card := _starter_definition()
	new_card["name"] = "Card %d" % (cards.size() + 1)
	cards.append(new_card)
	hand.append(cards.size() - 1)
	_select_card(cards.size() - 1)
	_save_try_settings()

## Right-click on a card's chip: Delete (not for your only card).
func _open_card_menu(index: int) -> void:
	if card_menu == null:
		card_menu = PopupMenu.new()
		card_menu.id_pressed.connect(func(_id): _remove_card(card_menu.get_meta("card", -1)))
		add_child(card_menu)
	card_menu.clear()
	card_menu.add_item("Delete \"%s\"" % str(cards[index].get("name", "card")), 0)
	card_menu.set_meta("card", index)
	card_menu.popup(Rect2i(Vector2i(get_global_mouse_position()), Vector2i.ZERO))

func _remove_current_card() -> void:
	_remove_card(current_card)

## Removes cards[index] and its copies in the hand; the card you're editing
## stays open (or its neighbour, when it's the one removed).
func _remove_card(index: int) -> void:
	if index < 0 or index >= cards.size():
		return
	if cards.size() == 1:
		# Your only card: start over with a fresh one (the Lab always has a card open).
		definition = _starter_definition()
		cards = [definition]
		current_card = 0
		hand = hand.filter(func(entry): return not entry is int)
		hand.append(0)
		_open_effect = 0
		_open_nested.clear()
		_load_definition_into_ui()
		_refresh()
		_save_try_settings()
		return
	cards[current_card] = definition
	var removed := index
	if removed < current_card:
		current_card -= 1
	cards.remove_at(removed)
	var kept: Array = []
	for entry in hand:
		if entry is int and entry == removed:
			continue
		kept.append(entry - 1 if entry is int and entry > removed else entry)
	hand = kept
	current_card = mini(current_card, cards.size() - 1)
	definition = cards[current_card]
	_open_effect = 0
	_open_nested.clear()
	_load_definition_into_ui()
	_refresh()
	_save_try_settings()

## Drops hand entries for cards that are gone; a custom card missing from the
## hand goes on the end.
func _fit_hand() -> void:
	# Your cards don't all have to be in the hand: a puzzle can use just some of them.
	hand = hand.filter(func(entry): return (entry is int and entry >= 0 and entry < cards.size()) or entry is String)

## How many of each custom card the hand has, one count per card.
func _card_copies() -> Array:
	var counts: Array = []
	counts.resize(cards.size())
	counts.fill(0)
	for entry in hand:
		if entry is int and entry < counts.size():
			counts[entry] += 1
	return counts

## The hand's built-in cards, in order.
func _other_cards() -> Array:
	return hand.filter(func(entry): return entry is String)

func _exit_tree() -> void:
	if _save_queued:
		_write_lab()  # a change still waiting to be saved
	for card in _builtin_cards.values():
		if card != null:
			card.free()
	_builtin_cards.clear()
	if preview_card != null:
		preview_card.free()
		preview_card = null

func _number_value(edit: LineEdit, fallback: int) -> int:
	return edit.text.to_int() if edit.text.is_valid_int() else fallback

func _on_main_menu() -> void:
	_save_try_settings()
	if OS.has_feature("web"):
		# The web build has no main menu: back to the website's home page.
		JavaScriptBridge.eval("window.location.href = '/';", true)
		return
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

## Opens the Library (your work is kept, as when leaving for the main menu).
func _on_go_to_library() -> void:
	_save_try_settings()
	get_tree().change_scene_to_file(get_node("/root/Background").ARCHIVE_SCENE)

# ---------------------------------------------------------------- test hand

## The Test hand, as the cards themselves, in the order the test puzzle deals
## them: each of your cards (one per copy), then the built-in cards, then "+".
## Clicking one of your cards opens it for editing; "×" takes a card out (your
## cards keep at least one, remove the card itself with "×" above the preview).
var _hand_dirty := false  # the hand changed while the Custom Puzzle tab was closed

func _rebuild_hand() -> void:
	if hand_slots == null:
		return
	_hand_dirty = false
	_fit_hand()
	for child in hand_slots.get_children():
		hand_slots.remove_child(child)
		child.queue_free()
	var total := 0
	var copies := _card_copies()
	var custom_cards: Array = []
	for i in cards.size():
		var made := CardFactory.create_card(cards[i])
		made.update_description_panel()
		custom_cards.append(made)
	for at in hand.size():
		var entry = hand[at]
		var slot: Control
		if entry is int:
			var i: int = entry
			slot = _hand_slot(at, custom_cards[i], i == current_card, func(): _open_card(i),
				func(): _remove_from_hand(at))
			slot.tooltip_text = "Your card. Click to edit it."
		else:
			var card := _builtin_card(str(entry))
			if card == null:
				continue
			slot = _hand_slot(at, card, false, Callable(), func(): _remove_from_hand(at))
		hand_slots.add_child(slot)
		total += 1
	for made in custom_cards:
		made.free()
	var add := Button.new()
	add.text = "+\nAdd card"
	add.custom_minimum_size = HAND_SLOT_SIZE
	add.focus_mode = Control.FOCUS_NONE
	add.tooltip_text = "Add one of your cards or a built-in card"
	add.add_theme_font_size_override("font_size", 13)
	add.add_theme_stylebox_override("normal", _box(Color(0, 0, 0, 0), C_ACCENT, 8, 4))
	add.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.04), C_MUTED, 8, 4))
	add.add_theme_stylebox_override("pressed", _box(Color(1, 1, 1, 0.08), C_TEXT, 8, 4))
	add.add_theme_color_override("font_color", C_MUTED)
	add.add_theme_color_override("font_hover_color", C_TEXT)
	add.pressed.connect(func(): _open_hand_picker(add))
	add.set_drag_forwarding(Callable(), _can_drop_hand_card, func(_pos, data): _move_in_hand(data["hand_slot"], hand.size()))
	hand_slots.add_child(add)
	if hand_title != null:
		hand_title.text = "Hand (%d card%s)" % [total, "" if total == 1 else "s"]
	_save_try_settings()

## One card in the hand: the card as it looks in game, an outline when it's the
## card you're editing (or on hover when clicking it opens it), and "×" in the
## corner when on_remove is valid.
func _hand_slot(at: int, card: Card, editing: bool, on_press: Callable, on_remove: Callable) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = HAND_SLOT_SIZE
	slot.set_meta("card_name", card.get_card_name())
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	var art: Control = load(PREVIEW_SCENE).instantiate()
	art.scale = Vector2.ONE * HAND_CARD_SCALE
	art.position = Vector2(HAND_SLOT_PAD, HAND_SLOT_PAD)
	slot.add_child(art)
	art.set_card(card)
	_ignore_mouse(art)
	var outline := Button.new()  # clicks and the highlight, over the card
	outline.set_anchors_preset(Control.PRESET_FULL_RECT)
	outline.focus_mode = Control.FOCUS_NONE
	var clear := Color(0, 0, 0, 0)
	var lit := _box(clear, C_TEXT, 10, 0)
	lit.set_border_width_all(2)
	outline.add_theme_stylebox_override("normal", lit if editing else _box(clear, clear, 10, 0))
	outline.add_theme_stylebox_override("hover", lit if on_press.is_valid() or editing else _box(clear, clear, 10, 0))
	outline.add_theme_stylebox_override("pressed", lit if on_press.is_valid() or editing else _box(clear, clear, 10, 0))
	outline.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if on_press.is_valid() else Control.CURSOR_ARROW
	if on_press.is_valid():
		outline.pressed.connect(on_press)
	# Drag a card onto another to move it there (onto "+" for the end).
	var drag_from := func(_pos) -> Variant:
		var ghost: Control = art.duplicate()
		ghost.position = -Vector2(60, 80) * HAND_CARD_SCALE
		ghost.modulate = Color(1, 1, 1, 0.85)
		var holder := Control.new()
		holder.add_child(ghost)
		outline.set_drag_preview(holder)
		slot.modulate = Color(1, 1, 1, 0.35)
		return {"hand_slot": at}
	var drop_on := func(pos: Vector2, data) -> void:
		_move_in_hand(data["hand_slot"], at + (1 if pos.x > outline.size.x / 2.0 else 0))
	outline.set_drag_forwarding(drag_from, _can_drop_hand_card, drop_on)
	slot.add_child(outline)
	if on_remove.is_valid():
		var remove := Button.new()
		remove.text = "×"
		remove.focus_mode = Control.FOCUS_NONE
		remove.tooltip_text = "Take out of the hand"
		remove.add_theme_font_size_override("font_size", 13)
		remove.add_theme_color_override("font_color", C_TEXT)
		remove.add_theme_stylebox_override("normal", _box(C_BG, C_ACCENT, 11, 0))
		remove.add_theme_stylebox_override("hover", _box(C_ACCENT, C_MUTED, 11, 0))
		remove.add_theme_stylebox_override("pressed", _box(C_ACCENT, C_TEXT, 11, 0))
		remove.custom_minimum_size = Vector2(22, 22)
		remove.size = Vector2(22, 22)
		remove.position = Vector2(HAND_SLOT_SIZE.x - 22, 0)
		remove.pressed.connect(on_remove)
		slot.add_child(remove)
		# Only while the pointer is on the card, so it doesn't cover the card's name.
		remove.visible = false
		var show_remove := func():
			if is_instance_valid(remove):
				remove.visible = slot.get_global_rect().has_point(slot.get_global_mouse_position())
		outline.mouse_entered.connect(show_remove)
		outline.mouse_exited.connect(func(): show_remove.call_deferred())
		remove.mouse_exited.connect(func(): show_remove.call_deferred())
	return slot

func _can_drop_hand_card(_pos, data) -> bool:
	return data is Dictionary and data.has("hand_slot")

## Moves the card at `from` so it lands before the card now at `to`
## (to == hand.size(): the end).
func _move_in_hand(from: int, to: int) -> void:
	if from < 0 or from >= hand.size():
		_rebuild_hand()
		return
	var entry = hand[from]
	hand.remove_at(from)
	if to > from:
		to -= 1
	hand.insert(clampi(to, 0, hand.size()), entry)
	_rebuild_hand()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and hand_slots != null:
		for slot in hand_slots.get_children():
			if slot is Control:
				slot.modulate = Color.WHITE

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

## "+": your cards first, then every built-in card.
var _picker_layer: Control  # the open "Add card" list (closes on a click outside it)

## The "Add card" list: your cards, then the built-in ones; hovering a name shows the card
## beside the list, clicking adds it to the end of the hand.
func _open_hand_picker(anchor: Control) -> void:
	_close_hand_picker()
	_fit_hand()
	_picker_layer = Control.new()
	_picker_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker_layer.z_index = 50
	add_child(_picker_layer)
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_hand_picker())
	_picker_layer.add_child(catcher)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(C_CARD, C_BORDER, 6, 4))
	panel.custom_minimum_size = Vector2(220, 0)
	_picker_layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 340)
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	var preview_holder := Control.new()
	preview_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picker_layer.add_child(preview_holder)
	var faces := {}  # entry -> its face, made on first hover
	var copies := _card_copies()
	list.add_child(_label("YOUR CARDS", 10, C_MUTED, true))
	for i in cards.size():
		_picker_item(list, str(cards[i].get("name", "Card %d" % (i + 1))), i, copies[i] >= ShareCode.MAX_COPIES, panel, preview_holder, faces)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	list.add_child(gap)
	list.add_child(_label("BUILT-IN CARDS", 10, C_MUTED, true))
	var full := _other_cards().size() >= ShareCode.MAX_OTHER_CARDS
	var used := _released_card_files()
	for choice in EffectRegistry.get_resource_choices("card"):
		if str(choice["path"]).get_file() in used:  # test cards no released puzzle uses are left out
			_picker_item(list, str(choice["label"]), str(choice["path"]), full, panel, preview_holder, faces)
	# Under the "+" slot, kept on screen.
	var at := anchor.global_position + Vector2(0, anchor.size.y + 4)
	var height := 348.0
	at.y = minf(at.y, size.y - height - 8.0)
	at.x = minf(at.x, size.x - 220.0 - 8.0)
	panel.position = at

static var _released_files: Array = []

## The scene files of the built-in cards released puzzles use (like the Library's Cards tab).
static func _released_card_files() -> Array:
	if _released_files.is_empty():
		var names := {}
		for entry in PuzzleArchive.load_bundled():
			for card_name in entry.get("cards", []):
				names[card_name] = true
		for card_name in names:
			var file := str(CardFaces.info(card_name).get("file", ""))
			if not file.is_empty():
				_released_files.append(file)
	return _released_files

func _picker_item(list: VBoxContainer, title: String, entry, disabled: bool, panel: Control, preview_holder: Control, faces: Dictionary) -> void:
	var item := Button.new()
	item.text = title
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.add_theme_stylebox_override("normal", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 4))
	item.add_theme_stylebox_override("disabled", _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 4))
	item.add_theme_stylebox_override("pressed", _box(C_ACCENT, Color.TRANSPARENT, 4, 4))
	item.disabled = disabled
	item.focus_mode = Control.FOCUS_NONE
	item.add_theme_color_override("font_color", C_TEXT)
	item.add_theme_color_override("font_hover_color", C_TEXT)
	item.add_theme_stylebox_override("hover", _box(C_ACCENT, Color.TRANSPARENT, 4, 4))
	item.pressed.connect(func():
		_close_hand_picker()
		_add_to_hand(entry))
	item.mouse_entered.connect(func(): _show_picker_preview(entry, item, panel, preview_holder, faces))
	list.add_child(item)

## The hovered card, beside the list (on the left when there's no room on the right).
func _show_picker_preview(entry, item: Control, panel: Control, preview_holder: Control, faces: Dictionary) -> void:
	for child in preview_holder.get_children():
		child.hide()
	if not faces.has(entry):
		var card: Card = CardFactory.create_card(cards[entry]) if entry is int else _instantiate_card(entry)
		if card == null:
			return
		var face := CardFaces.strip(card)
		face.scale = Vector2(1.25, 1.25)
		face.position = Vector2.ZERO  # card scenes keep their own position
		var nodes: Array = [face]
		while not nodes.is_empty():  # the preview never takes clicks
			var node = nodes.pop_back()
			if node is Control:
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nodes.append_array(node.get_children())
		preview_holder.add_child(face)
		faces[entry] = face
	faces[entry].show()
	var face_size := Vector2(120, 160) * 1.25
	var at := Vector2(panel.position.x + panel.size.x + 8, item.global_position.y + item.size.y / 2.0 - face_size.y / 2.0)
	if at.x + face_size.x > size.x:
		at.x = panel.position.x - face_size.x - 8
	at.y = clampf(at.y, 8.0, size.y - face_size.y - 8.0)
	preview_holder.position = at

func _instantiate_card(path: String) -> Card:
	var scene = load(path) if ResourceLoader.exists(path) else null
	var node = scene.instantiate() if scene is PackedScene else null
	if node is Card:
		return node
	if node != null:
		node.free()
	return null

func _close_hand_picker() -> void:
	if _picker_layer != null and is_instance_valid(_picker_layer):
		_picker_layer.queue_free()
	_picker_layer = null

func _on_hand_pick(id: int) -> void:
	if id < 0 or id >= _hand_choices.size():
		return
	_add_to_hand(_hand_choices[id])

## entry: the index of one of your cards, or a built-in card's scene path.
## It goes on the end of the hand.
func _add_to_hand(entry) -> void:
	_fit_hand()
	if entry is int and _card_copies()[entry] < ShareCode.MAX_COPIES:
		hand.append(entry)
	elif entry is String and _other_cards().size() < ShareCode.MAX_OTHER_CARDS:
		hand.append(entry)
	_rebuild_hand()

## Takes out the card at that place in the hand (your cards keep one copy).
func _remove_from_hand(at: int) -> void:
	if at < 0 or at >= hand.size():
		return
	hand.remove_at(at)  # your card stays in the Lab (Custom Cards) even with no copy in the hand
	_rebuild_hand()

## Built-in cards for the hand, made once from their scenes (freed with the Card Lab).
var _builtin_cards: Dictionary = {}

func _builtin_card(path: String) -> Card:
	if not _builtin_cards.has(path):
		var made: Card = null
		var scene = load(path) if ResourceLoader.exists(path) else null
		if scene is PackedScene:
			var node = scene.instantiate()
			if node is Card:
				made = node
				made.update_description_panel()
			elif node != null:
				node.free()
		_builtin_cards[path] = made
	return _builtin_cards[path]

# ---------------------------------------------------------------- saved on this device

## The Card Lab's cards and Test hand, kept between games (user:// is the game's
## save folder; in a browser, the site's storage).
const SAVE_PATH := "user://card_lab.json"

## Dev runs (a card from a file, a test hand from the command line) and tests
## don't touch your saved cards.
static func _saving_allowed() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--card-json=") or arg.begins_with("--try-cards=") or arg.begins_with("--import-code=") \
				or arg.begins_with("--screenshot="):
			return false
	return true


var _save_queued := false

## Saves a moment after the last change (typing makes many changes; each write is costly on
## the web), and right away when leaving the Puzzle Lab.
func _save_lab() -> void:
	if not _saving_allowed() or cards.is_empty() or _save_queued:
		return
	_save_queued = true
	get_tree().create_timer(0.4).timeout.connect(_write_lab)

func _write_lab() -> void:
	if not _save_queued:
		return
	_save_queued = false
	cards[current_card] = definition
	var data := {"version": 1, "cards": cards, "current": current_card, "settings": _try_settings()}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

## Loads the saved cards (and puts the saved Test hand in Background for
## _load_try_settings). False when there's nothing saved or it can't be read.
func _load_saved_lab(background) -> bool:
	if DisplayServer.get_name() == "headless" or not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (data is Dictionary) or not (data.get("cards") is Array):
		return false
	var saved: Array = data["cards"].filter(func(card): return card is Dictionary).slice(0, MAX_CARDS)
	if saved.is_empty():
		return false
	cards = saved
	current_card = clampi(int(data.get("current", 0)), 0, cards.size() - 1)
	definition = cards[current_card]
	if background != null and data.get("settings") is Dictionary:
		background.card_builder_try_settings = data["settings"]
	return true

## Try-it settings live in Background so they survive a trip to the test puzzle.
func _save_try_settings() -> void:
	var background = get_node_or_null("/root/Background")
	if background == null:
		return
	background.card_builder_try_settings = _try_settings()
	_save_lab()

func _try_settings() -> Dictionary:
	return {
		"hp": _number_value(test_hp, 10), "energy": _number_value(test_energy, 5),
		"enemy_hp": _number_value(test_enemy_hp, 20), "copies": _card_copies()[0] if not cards.is_empty() else 1,
		"card_copies": _card_copies(),
		"other_cards": _other_cards(),
		"order": _hand_order(),
		"name": puzzle_name_edit.text.strip_edges() if puzzle_name_edit != null else "",
		"author": author_edit.text.strip_edges() if author_edit != null else "",
		"difficulty": difficulty_pick.selected if difficulty_pick != null else 0,
	}

## The hand's order as ShareCode keeps it: i = cards[i], -1 - k = the k-th
## built-in card.
func _hand_order() -> Array:
	var order: Array = []
	var built_in := 0
	for entry in hand:
		if entry is int:
			order.append(entry)
		else:
			order.append(-1 - built_in)
			built_in += 1
	return order

func _load_try_settings() -> void:
	var background = get_node_or_null("/root/Background")
	var settings: Dictionary = background.card_builder_try_settings if background != null else {}
	test_hp.text = str(int(settings.get("hp", 10)))
	test_energy.text = str(int(settings.get("energy", 5)))
	test_enemy_hp.text = str(int(settings.get("enemy_hp", 20)))
	puzzle_name_edit.text = str(settings.get("name", ""))
	author_edit.text = str(settings.get("author", ""))
	difficulty_pick.select(clampi(int(settings.get("difficulty", 0)), 0, 5))
	hand = ShareCode.hand_from(settings, cards.size(), DEFAULT_OTHER_CARDS)
	_rebuild_hand()

## "res://Scenes/SlashCard.tscn" -> "slash-card.PNG", the name puzzle URLs use.
func _url_card_name(scene_path: String) -> String:
	return scene_path.get_file().trim_suffix("Card.tscn").to_lower() + "-card.PNG"

func _on_try_it() -> void:
	_save_try_settings()
	cards[current_card] = definition
	_fit_hand()
	if hand.is_empty():
		_show_tab(TEST_TAB)
		share_status.visible = true
		share_status.text = "The hand is empty. Add cards to it below, then Play test."
		return
	# The hand in its order: your cards are C<n> (the n-th in custom_cards),
	# built-in ones E<n> (the n-th in cards).
	var dealt: Array = []
	var card_names: Array[String] = []
	var order: Array = []
	for entry in hand:
		if entry is int:
			order.append("C%d" % dealt.size())
			dealt.append(cards[entry])
		else:
			order.append("E%d" % card_names.size())
			card_names.append(_url_card_name(entry))
	# Same URL format as puzzle links: built-in cards in "cards", the custom card in "custom_cards".
	var search := "?cards=%s&php=%d&pnrg=%d&ehp=%d&enemy_name=%s&author=%s&card_order=%s&custom_cards=%s" % [
		Marshalls.utf8_to_base64(",".join(card_names).uri_encode()).uri_encode(),
		_number_value(test_hp, 10), _number_value(test_energy, 5), _number_value(test_enemy_hp, 20),
		_puzzle_name().uri_encode(), (author_edit.text.strip_edges() if not author_edit.text.strip_edges().is_empty() else "You").uri_encode(),
		Marshalls.utf8_to_base64(JSON.stringify(order)).uri_encode(),
		Marshalls.utf8_to_base64(JSON.stringify(dealt)).uri_encode(),
	]
	get_node("/root/Background").start_card_builder_try(search)
