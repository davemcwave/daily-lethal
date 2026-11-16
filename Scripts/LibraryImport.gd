class_name LibraryImport
## The Library's Import code box (both tabs): paste a share code, then add its cards and
## puzzles, or just its cards, to the Library (CustomLibrary). Afterwards the Library
## reopens on the tab it was on, showing only custom content, with a short note.

const FONT_BOLD: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf")
const FONT_MEDIUM: FontFile = preload("res://Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf")
const C_PANEL := Color("#18181b")
const C_BORDER := Color("#3f3f46")
const C_TEXT := Color("#fafafa")
const C_MUTED := Color("#a1a1aa")
const C_GOLD := Color("#ffce4e")
const C_DANGER := Color("#dc2626")

## Opens the box over `parent` (a full-screen Library view). `scene` is the view's scene,
## reopened after an import.
static func open(parent: Control, scene: String) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 60
	parent.add_child(layer)
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
	panel.custom_minimum_size = Vector2(440, 0)
	var box_style := _box(C_PANEL, C_BORDER)
	box_style.set_content_margin_all(16)
	box_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", box_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label("Import a share code", FONT_BOLD, 18, C_TEXT))
	var hint := _label("Paste a code someone shared. Its cards and puzzles go into your Library, marked Custom.", FONT_MEDIUM, 12, C_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 100)
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.add_theme_font_size_override("font_size", 11)
	edit.placeholder_text = ShareCode.PREFIX_V3 + "..."
	var clipboard := DisplayServer.clipboard_get().strip_edges()
	for prefix in [ShareCode.PREFIX_V3, ShareCode.PREFIX, ShareCode.PREFIX_V1]:
		if clipboard.begins_with(prefix):
			edit.text = clipboard
	box.add_child(edit)
	var status := _label("", FONT_MEDIUM, 12, Color("#f87171"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)
	var cancel := _button("Cancel", false)
	cancel.pressed.connect(layer.queue_free)
	buttons.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	var choices: Array = []
	for choice in [["Cards only", false, false], ["Cards and puzzles", true, true]]:
		var button := _button(choice[0], choice[2])
		button.pressed.connect(func(): _import(parent, scene, edit.text, choice[1], status, buttons, choices))
		buttons.add_child(button)
		choices.append(button)
	edit.text_changed.connect(func(): _reset_choices(buttons, choices, status))
	edit.grab_focus()

## Imports, unless that would overwrite cards or puzzles with the same names: then the box
## says which, and a red Overwrite button (in place of the two choices) confirms.
static func _import(parent: Control, scene: String, code: String, include_puzzles: bool, status: Label,
		buttons: HBoxContainer, choices: Array) -> void:
	var decoded := ShareCode.decode_library(code)
	status.add_theme_color_override("font_color", Color("#f87171"))
	if decoded.has("error"):
		status.text = decoded["error"]
		return
	var found := CustomLibrary.conflicts(decoded, include_puzzles)
	if found["cards"].is_empty() and found["puzzles"].is_empty():
		_finish_import(parent, scene, decoded, include_puzzles)
		return
	var total: int = found["cards"].size() + found["puzzles"].size()
	status.add_theme_color_override("font_color", C_TEXT)
	status.text = "Your Library already has %s. Overwrite %s with the imported version?" % [
		CustomLibrary.describe_conflicts(found), "it" if total == 1 else "them"]
	for choice in choices:
		choice.hide()
	var overwrite := _button("Overwrite", false)
	overwrite.name = "Overwrite"
	for state in ["normal", "hover", "pressed"]:
		var red := _box(C_DANGER if state != "hover" else C_DANGER.lightened(0.1), C_DANGER)
		overwrite.add_theme_stylebox_override(state, red)
	overwrite.pressed.connect(func(): _finish_import(parent, scene, decoded, include_puzzles))
	buttons.add_child(overwrite)

## Back to the two choices (the code was edited after an overwrite question).
static func _reset_choices(buttons: HBoxContainer, choices: Array, status: Label) -> void:
	var overwrite := buttons.get_node_or_null("Overwrite")
	if overwrite != null:
		overwrite.queue_free()
	for choice in choices:
		choice.show()
	status.text = ""

static func _finish_import(parent: Control, scene: String, decoded: Dictionary, include_puzzles: bool) -> void:
	var result := CustomLibrary.save(decoded, include_puzzles)
	var parts: Array = []
	if result["cards"] > 0:
		parts.append(_count(result["cards"], "card"))
	if result["puzzles"] > 0:
		parts.append(_count(result["puzzles"], "puzzle"))
	var overwritten: int = result["updated"] + result["replaced"]
	if overwritten > 0:
		parts.append("%d overwritten" % overwritten)
	var background = parent.get_node("/root/Background")
	background.library_notice = ("Imported: %s." % ", ".join(parts)) if not parts.is_empty() else "Already in your Library."
	parent.get_tree().change_scene_to_file(scene)

static func _count(n: int, noun: String) -> String:
	return "%d new %s%s" % [n, noun, "" if n == 1 else "s"]

## Shows Background.library_notice (once) as a small note at the bottom of the view.
static func show_notice(parent: Control) -> void:
	var background = parent.get_node("/root/Background")
	if background.library_notice.is_empty():
		return
	var note := PanelContainer.new()
	var style := _box(C_PANEL, C_GOLD)
	style.set_content_margin_all(10)
	note.add_theme_stylebox_override("panel", style)
	note.add_child(_label(background.library_notice, FONT_BOLD, 13, C_GOLD))
	background.library_notice = ""
	note.z_index = 60
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(note)
	await parent.get_tree().process_frame
	note.position = Vector2((parent.size.x - note.size.x) / 2.0, parent.size.y - note.size.y - 48.0)
	await parent.get_tree().create_timer(3.0).timeout
	if is_instance_valid(note):
		var fade := note.create_tween()
		fade.tween_property(note, "modulate:a", 0.0, 0.4)
		fade.tween_callback(note.queue_free)

## The Import code button for a Library view's top bar.
static func button(parent: Control, scene: String) -> Button:
	var import_button := _button("Import code", false)
	import_button.pressed.connect(func(): open(parent, scene))
	return import_button

static func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

static func _button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 13)
	var fg := Color("#18181b") if primary else C_TEXT
	var bg := C_GOLD if primary else C_PANEL
	b.add_theme_stylebox_override("normal", _box(bg, C_GOLD if primary else C_BORDER))
	b.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), C_GOLD if primary else Color("#52525b")))
	b.add_theme_stylebox_override("pressed", _box(bg.darkened(0.15), C_BORDER))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, fg)
	return b
