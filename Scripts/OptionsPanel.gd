extends Control

@onready var audio_handler = $"/root/AudioHandler"
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicContainer/MusicSlider
@onready var music_value_label: Label = $Panel/VBoxContainer/MusicContainer/MusicValueLabel
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXContainer/SFXSlider
@onready var sfx_value_label: Label = $Panel/VBoxContainer/SFXContainer/SFXValueLabel
@onready var mute_checkbox: CheckBox = $Panel/VBoxContainer/MuteContainer/MuteCheckBox
@onready var sfx_timer: Timer = $Panel/VBoxContainer/SFXContainer/SFXSlider/Timer
signal closed

var can_sfx_slider_make_noise: bool = true

func _ready() -> void:
	_add_replay_tutorial_button()
	# Initialize values from AudioHandler
	var bg_music = audio_handler.get_node_or_null("BGMusic")
	if bg_music:
		music_slider.value = bg_music.volume_db
		music_value_label.text = str(int(bg_music.volume_db)) + " dB"

	var hit_sfx = audio_handler.get_node_or_null("HitSFX")
	if hit_sfx:
		sfx_slider.value = hit_sfx.volume_db
		sfx_value_label.text = str(int(hit_sfx.volume_db)) + " dB"

	mute_checkbox.button_pressed = audio_handler.mute_all
	_add_damage_math_row()
	if OS.has_feature("web"):  # the web builds have no sound: no audio settings there (after Damage Math copies Mute's row)
		for row in ["MusicContainer", "SFXContainer", "MuteContainer"]:
			$Panel/VBoxContainer.get_node(row).hide()
	_apply_style()

## "Show Damage Math": a row like Mute's, under it (the panel grows to fit).
func _add_damage_math_row() -> void:
	var background = get_node_or_null("/root/Background")
	if background == null:
		return
	var mute_row: HBoxContainer = $Panel/VBoxContainer/MuteContainer
	var row: HBoxContainer = mute_row.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)  # not Mute's signal
	row.name = "DamageMathContainer"
	mute_row.add_sibling(row)
	var box: CheckBox = row.get_node("MuteCheckBox")
	box.button_pressed = background.show_damage_math
	box.toggled.connect(func(on: bool): background.set_show_damage_math(on))
	var label: RichTextLabel = row.get_node("MuteLabel")
	label.custom_minimum_size.x = 220
	label.text = "[shake rate=2.0 level=2 connected=1]Show Damage Math[/shake]"

# ---------------------------------------------------------------- look
# Same look as the Puzzle Archive: dark panel, thin borders, Quicksand, gold accents.

const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const COLOR_PANEL := Color("#111113")
const COLOR_CONTROL := Color("#18181b")
const COLOR_BORDER := Color("#3f3f46")
const COLOR_TEXT := Color("#fafafa")
const COLOR_MUTED := Color("#a1a1aa")
const COLOR_GOLD := Color("#ffce4e")
const COLOR_DANGER := Color("#ef6b78")

func _apply_style() -> void:
	var panel: Panel = $Panel
	var column: VBoxContainer = $Panel/VBoxContainer
	panel.add_theme_stylebox_override("panel", _box(Color(COLOR_PANEL, 0.98), COLOR_BORDER, 10, 0))
	column.add_theme_constant_override("separation", 14)
	column.offset_left = 28
	column.offset_right = -28
	column.offset_top = 22
	column.offset_bottom = -22
	var title: RichTextLabel = $Panel/VBoxContainer/TitleLabel
	title.text = "Options"
	title.add_theme_font_override("normal_font", FONT_BOLD)
	title.add_theme_font_size_override("normal_font_size", 22)
	title.add_theme_color_override("default_color", COLOR_TEXT)
	for row in column.get_children():
		for child in row.get_children():
			_style_control(child, row.name)
	panel.offset_left = -210
	panel.offset_right = 210
	_fit_panel.call_deferred()

## The panel fits its rows, centered (once the labels have measured their text).
func _fit_panel() -> void:
	await get_tree().process_frame
	var panel: Panel = $Panel
	var column: VBoxContainer = $Panel/VBoxContainer
	var height := 0.0
	for row in column.get_children():
		if row is Control and row.visible:
			height += row.get_combined_minimum_size().y
	var shown := column.get_children().filter(func(row): return row is Control and row.visible).size()
	height += column.get_theme_constant("separation") * (shown - 1) + 44
	panel.offset_top = -height / 2.0
	panel.offset_bottom = height / 2.0

func _style_control(control: Node, row_name: String) -> void:
	if control is RichTextLabel:
		var label := control as RichTextLabel
		label.text = label.get_parsed_text()  # no shaking text
		label.add_theme_font_override("normal_font", FONT_MEDIUM)
		label.add_theme_font_size_override("normal_font_size", 14)
		label.add_theme_color_override("default_color", Color("#e4e4e7"))
		label.fit_content = true
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	elif control is Label:
		control.add_theme_font_override("font", FONT_MEDIUM)
		control.add_theme_font_size_override("font_size", 13)
		control.add_theme_color_override("font_color", COLOR_MUTED)
		control.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	elif control is HSlider:
		_style_slider(control)
	elif control is CheckBox:
		_style_checkbox(control)
	elif control is Button:
		var kind := "primary" if row_name == "ButtonContainer" else ("danger" if control.name == "DeleteSaveFileButton" else "secondary")
		_style_button(control, kind)

func _box(bg: Color, border: Color, radius: int, pad: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = pad
	box.content_margin_right = pad
	box.content_margin_top = pad / 2.0
	box.content_margin_bottom = pad / 2.0
	return box

func _style_button(button: Button, kind: String) -> void:
	var bg := COLOR_CONTROL
	var fg := COLOR_TEXT
	var border := COLOR_BORDER
	match kind:
		"primary":
			bg = COLOR_GOLD
			fg = Color("#18181b")
			border = COLOR_GOLD
		"danger":
			bg = Color(COLOR_DANGER, 0.0)
			fg = COLOR_DANGER
			border = Color(COLOR_DANGER, 0.6)
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _box(bg, border, 6, 14))
	button.add_theme_stylebox_override("hover", _box(bg.lightened(0.1) if kind != "danger" else Color(COLOR_DANGER, 0.12), border, 6, 14))
	button.add_theme_stylebox_override("pressed", _box(bg.darkened(0.15) if kind != "danger" else Color(COLOR_DANGER, 0.2), border, 6, 14))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, fg)
	button.custom_minimum_size = Vector2(button.custom_minimum_size.x, 34)

func _style_slider(slider: HSlider) -> void:
	var track := _box(Color("#27272a"), Color("#27272a"), 3, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track)
	var filled := _box(COLOR_GOLD, COLOR_GOLD, 3, 0)
	filled.content_margin_top = 3
	filled.content_margin_bottom = 3
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob := _circle_texture(14, COLOR_TEXT)
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)

func _style_checkbox(box: CheckBox) -> void:
	box.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	box.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	box.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	box.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	box.add_theme_icon_override("checked", _checkbox_texture(true))
	box.add_theme_icon_override("unchecked", _checkbox_texture(false))

## A filled circle (the slider knob).
func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r := diameter / 2.0
	for y in diameter:
		for x in diameter:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			image.set_pixel(x, y, Color(color, clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)

## A rounded box: gold with a dark check when on, an empty outline when off.
func _checkbox_texture(checked: bool) -> ImageTexture:
	var n := 18
	var image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var inside := x >= 1 and y >= 1 and x <= n - 2 and y <= n - 2
			var corner := (x <= 2 or x >= n - 3) and (y <= 2 or y >= n - 3) and not (x in [2, n - 3] or y in [2, n - 3])
			if not inside or corner:
				continue
			var edge := x == 1 or y == 1 or x == n - 2 or y == n - 2
			if checked:
				image.set_pixel(x, y, COLOR_GOLD)
			elif edge:
				image.set_pixel(x, y, Color("#71717a"))
			else:
				image.set_pixel(x, y, COLOR_CONTROL)
	if checked:
		# The check mark: down from (4, 9) to (7, 12), then up to (13, 5).
		for t in 20:
			var u := t / 19.0
			for p in [Vector2(4, 9).lerp(Vector2(7, 12), u), Vector2(7, 12).lerp(Vector2(13, 5), u)]:
				for dx in [0, 1]:
					image.set_pixel(int(p.x) + dx, int(p.y), Color("#18181b"))
	return ImageTexture.create_from_image(image)

func _on_music_slider_value_changed(value: float) -> void:
	var bg_music = audio_handler.get_node_or_null("BGMusic")
	if bg_music:
		bg_music.volume_db = value
	music_value_label.text = str(int(value)) + " dB"
	audio_handler.save_audio_setting("music_db", value)

func _on_sfx_slider_value_changed(value: float) -> void:
	for child in audio_handler.get_children():
		if child is AudioStreamPlayer and child.name != "BGMusic":
			child.volume_db = value
	sfx_value_label.text = str(int(value)) + " dB"
	audio_handler.save_audio_setting("sfx_db", value)
	if can_sfx_slider_make_noise:
		can_sfx_slider_make_noise = false
		audio_handler.play_sfx("HitSFX")
		
		if sfx_timer.is_stopped():
			sfx_timer.start()

func _on_mute_check_box_toggled(toggled: bool) -> void:
	audio_handler.mute_all = toggled
	audio_handler.save_audio_setting("mute_all", toggled)
	if toggled:
		audio_handler.stop_sfx("BGMusic")
	else:
		audio_handler.play_sfx("BGMusic", 1)

func _on_close_button_pressed() -> void:
	closed.emit()
	queue_free()

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
		queue_free()


func _on_sfx_timer_timeout():
	can_sfx_slider_make_noise = true


## "Replay Tutorial", next to Delete Save File (the main menu has no Tutorial item).
func _add_replay_tutorial_button() -> void:
	var delete_row: Control = $Panel/VBoxContainer/DeleteSaveFileContainer
	var row: Control = delete_row.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANTIATION)
	row.name = "ReplayTutorialContainer"
	var button: Button = row.get_node("DeleteSaveFileButton")
	button.name = "ReplayTutorialButton"
	button.text = "Replay Tutorial"
	button.pressed.connect(_on_replay_tutorial_pressed)
	delete_row.add_sibling(row)
	delete_row.get_parent().move_child(row, delete_row.get_index())

func _on_replay_tutorial_pressed() -> void:
	var background = $"/root/Background"
	background.set_tutorial_seen()
	background.set_show_tutorial(true)
	background.set_from_story_view(true)
	background.set_puzzle_scene("res://Scenes/Puzzles/Tutorial-Puzzle.tscn")
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.tscn")

func _on_delete_save_file_button_pressed():
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to delete your story progress?\n\nThis cannot be undone."
	confirm_dialog.ok_button_text = "Delete"
	confirm_dialog.cancel_button_text = "Cancel"
	confirm_dialog.confirmed.connect(_on_delete_confirmed)
	confirm_dialog.canceled.connect(func(): confirm_dialog.queue_free())
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	var save_path := "user://story_progress.save"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	# Clear the in-memory progress too
	var background = $"/root/Background"
	if background.has_method("load_story_progress"):
		background.completed_story_puzzles.clear()
		background.last_completed_story_puzzle = ""
