extends Control
## The settings panel (main menu, and the in-game Options button): Audio, Display and Game
## sections of rows, a label and a short description on the left and the control on the
## right. Built in code over the scene's Overlay and Panel; same look as the Library and the
## Puzzle Lab (dark panel, thin borders, Quicksand, gold accents).

signal closed

@onready var audio_handler = $"/root/AudioHandler"
@onready var background = $"/root/Background"

const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const COLOR_PANEL := Color("#111113")
const COLOR_CONTROL := Color("#18181b")
const COLOR_BORDER := Color("#27272a")
const COLOR_TEXT := Color("#fafafa")
const COLOR_MUTED := Color("#a1a1aa")
const COLOR_GOLD := Color("#ffce4e")
const COLOR_DANGER := Color("#dc2626")
const PANEL_WIDTH := 480.0
## Volume sliders show 0-100%; the saved value stays in dB, -40 (0%) to 0 (100%).
const MIN_DB := -40.0

var column: VBoxContainer
var _sfx_can_sound := true

func _ready() -> void:
	# The scene's old rows are replaced by the layout below.
	$Panel/VBoxContainer.queue_free()
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	closed.emit()
	queue_free()

# ---------------------------------------------------------------- layout

func _build() -> void:
	var panel: Panel = $Panel
	panel.add_theme_stylebox_override("panel", _box(COLOR_PANEL, COLOR_BORDER, 12))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	# Header: title and a close button.
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("Settings", FONT_BOLD, 20, COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _button("✕", "ghost")
	close.custom_minimum_size = Vector2(30, 30)
	close.pressed.connect(_close)
	header.add_child(close)

	if not OS.has_feature("web"):  # the web builds have no sound
		_section("AUDIO")
		_row("Music", "", _volume_slider("BGMusic", "music_db"))
		_row("Sound effects", "", _volume_slider("", "sfx_db"))
		_row("Mute all", "", _switch(audio_handler.mute_all, _on_mute_toggled))

	_section("DISPLAY")
	if background.can_go_fullscreen():
		_row("Fullscreen", "F11 or Alt+Enter also switch.", _switch(background.fullscreen, func(on): background.set_fullscreen(on)))
	_row("Show damage math", "Shows how a held attack's damage is worked out.",
		_switch(background.show_damage_math, func(on): background.set_show_damage_math(on)))

	_section("GAME")
	var replay := _button("Replay", "secondary")
	replay.pressed.connect(_on_replay_tutorial_pressed)
	_row("Tutorial", "", replay)
	var delete := _button("Delete", "danger")
	delete.pressed.connect(func():
		if delete.text != "Delete?":
			delete.text = "Delete?"  # asks once more
			_set_danger(delete, true)
			return
		_delete_story_progress()
		delete.text = "Deleted"
		delete.disabled = true)
	delete.mouse_exited.connect(func():
		if delete.text == "Delete?":
			delete.text = "Delete"
			_set_danger(delete, false))
	_row("Story progress", "Clears your story map. Can't be undone.", delete)

	# Footer.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	column.add_child(gap)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)
	var done := _button("Done", "primary")
	done.custom_minimum_size = Vector2(96, 34)
	done.pressed.connect(_close)
	footer.add_child(done)
	_fit_panel.call_deferred()

## A small heading with a line under it.
func _section(text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 2)
	column.add_child(gap)
	column.add_child(_label(text, FONT_BOLD, 11, COLOR_MUTED))
	var rule := ColorRect.new()
	rule.color = COLOR_BORDER
	rule.custom_minimum_size = Vector2(0, 1)
	column.add_child(rule)

## A setting: its name (and a muted description under it) on the left, the control right.
func _row(title: String, description: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	text.add_child(_label(title, FONT_MEDIUM, 14, COLOR_TEXT))
	if not description.is_empty():
		var hint := _label(description, FONT_MEDIUM, 11, COLOR_MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(hint)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)

## The panel fits its rows, centered.
func _fit_panel() -> void:
	await get_tree().process_frame
	var panel: Panel = $Panel
	var height: float = column.get_combined_minimum_size().y + 38
	panel.offset_left = -PANEL_WIDTH / 2.0
	panel.offset_right = PANEL_WIDTH / 2.0
	panel.offset_top = -height / 2.0
	panel.offset_bottom = height / 2.0

# ---------------------------------------------------------------- controls

## A 0-100% volume slider for one player ("BGMusic") or, with "", every sound effect.
func _volume_slider(player_name: String, setting: String) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(150, 20)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	_style_slider(slider)
	var reference = audio_handler.get_node_or_null(player_name if not player_name.is_empty() else "HitSFX")
	var db: float = reference.volume_db if reference != null else -12.0
	slider.value = roundf(clampf((db - MIN_DB) / -MIN_DB, 0.0, 1.0) * 100.0)
	var value_label := _label("%d%%" % int(slider.value), FONT_MEDIUM, 12, COLOR_MUTED)
	value_label.custom_minimum_size = Vector2(36, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(func(value: float):
		value_label.text = "%d%%" % int(value)
		var new_db: float = MIN_DB + value / 100.0 * -MIN_DB if value > 0 else -80.0
		for child in audio_handler.get_children():
			if child is AudioStreamPlayer and ((child.name == player_name) if not player_name.is_empty() else child.name != "BGMusic"):
				child.volume_db = new_db
		audio_handler.save_audio_setting(setting, new_db)
		if player_name.is_empty() and _sfx_can_sound:  # a sample of the new level
			_sfx_can_sound = false
			audio_handler.play_sfx("HitSFX")
			get_tree().create_timer(0.25).timeout.connect(func(): _sfx_can_sound = true))
	box.add_child(slider)
	box.add_child(value_label)
	return box

func _on_mute_toggled(on: bool) -> void:
	audio_handler.mute_all = on
	audio_handler.save_audio_setting("mute_all", on)
	if on:
		audio_handler.stop_sfx("BGMusic")
	else:
		audio_handler.play_sfx("BGMusic", 1)

## An on/off switch (a pill with a knob; gold when on).
func _switch(on: bool, on_toggled: Callable) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.button_pressed = on
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_icon_override("checked", _switch_icon(true))
	toggle.add_theme_icon_override("unchecked", _switch_icon(false))
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		toggle.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.toggled.connect(on_toggled)
	return toggle

static var _switch_icons := {}
static func _switch_icon(on: bool) -> ImageTexture:
	if _switch_icons.has(on):
		return _switch_icons[on]
	var w := 36
	var h := 20
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := COLOR_GOLD if on else Color("#3f3f46")
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, h / 2.0, w - h / 2.0)  # the pill: a rectangle with round ends
			var d := p.distance_to(Vector2(cx, h / 2.0))
			var color := Color(0, 0, 0, 0)
			if d <= h / 2.0:
				color = track
				color.a = clampf(h / 2.0 - d + 0.5, 0.0, 1.0)
			var k := p.distance_to(Vector2(knob_x, h / 2.0))
			if k <= h / 2.0 - 2.5:
				var knob := Color("#18181b") if on else COLOR_TEXT
				color = color.lerp(knob, clampf(h / 2.0 - 2.5 - k + 0.5, 0.0, 1.0))
			image.set_pixel(x, y, color)
	_switch_icons[on] = ImageTexture.create_from_image(image)
	return _switch_icons[on]

func _style_slider(slider: HSlider) -> void:
	var track := _box(Color("#3f3f46"), Color(0, 0, 0, 0), 3)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := _box(COLOR_GOLD, Color(0, 0, 0, 0), 3)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _knob_icon()
	for icon in ["grabber", "grabber_highlight"]:
		slider.add_theme_icon_override(icon, knob)

static var _knob: ImageTexture
static func _knob_icon() -> ImageTexture:
	if _knob != null:
		return _knob
	var n := 16
	var image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(n / 2.0, n / 2.0))
			var color := COLOR_TEXT
			color.a = clampf(n / 2.0 - 1.0 - d + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, color)
	_knob = ImageTexture.create_from_image(image)
	return _knob

func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

## kind: "primary" (gold), "secondary" (outlined), "danger" (red outline), "ghost" (no frame).
func _button(text: String, kind: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 13)
	button.custom_minimum_size = Vector2(84, 30) if kind != "ghost" else Vector2.ZERO
	var bg := COLOR_GOLD if kind == "primary" else (COLOR_CONTROL if kind != "ghost" else Color(0, 0, 0, 0))
	var border := COLOR_GOLD if kind == "primary" else (Color("#7f1d1d") if kind == "danger" else (Color("#3f3f46") if kind != "ghost" else Color(0, 0, 0, 0)))
	var fg := Color("#18181b") if kind == "primary" else (Color("#f87171") if kind == "danger" else (COLOR_TEXT if kind != "ghost" else COLOR_MUTED))
	button.add_theme_stylebox_override("normal", _box(bg, border, 6))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.1) if kind != "ghost" else Color("#27272a"), border, 6))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.15) if kind != "ghost" else Color("#27272a"), border, 6))
	button.add_theme_stylebox_override("disabled", _box(COLOR_CONTROL, Color("#3f3f46"), 6))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, fg if state != "font_hover_color" or kind != "ghost" else COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	return button

## Delete's second step: solid red.
func _set_danger(button: Button, armed: bool) -> void:
	var bg := COLOR_DANGER if armed else COLOR_CONTROL
	var border := COLOR_DANGER if armed else Color("#7f1d1d")
	button.add_theme_stylebox_override("normal", _box(bg, border, 6))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.1), border, 6))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE if armed else Color("#f87171"))

func _box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

# ---------------------------------------------------------------- actions

func _on_replay_tutorial_pressed() -> void:
	background.set_tutorial_seen()
	background.set_show_tutorial(true)
	background.set_from_story_view(true)
	background.set_puzzle_scene("res://Scenes/Puzzles/Tutorial-Puzzle.tscn")
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.tscn")

func _delete_story_progress() -> void:
	var save_path := "user://story_progress.save"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	background.completed_story_puzzles.clear()
	background.last_completed_story_puzzle = ""

# ---------------------------------------------------------------- scene signals
# OptionsPanel.tscn still connects its old rows' signals here; those rows are removed in
# _ready, so only the Overlay's does anything.

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()

func _on_music_slider_value_changed(_value: float) -> void:
	pass

func _on_sfx_slider_value_changed(_value: float) -> void:
	pass

func _on_sfx_timer_timeout() -> void:
	pass

func _on_mute_check_box_toggled(_toggled: bool) -> void:
	pass

func _on_delete_save_file_button_pressed() -> void:
	pass

func _on_close_button_pressed() -> void:
	_close()
