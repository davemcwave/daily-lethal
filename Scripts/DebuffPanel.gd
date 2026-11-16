extends Panel
class_name DebuffPanel

@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
var debuff: Debuff

## Every status box is this wide: BuffPanel's minimum width (yours and the
## enemy's buffs), so debuffs don't stretch to fill their column.
const WIDTH := 70.0

func _ready() -> void:
	custom_minimum_size.x = WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_hide_description)
	tree_exiting.connect(_hide_description)

func blink() -> void:
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	modulate = Color('b72e31')
	
	
func set_debuff(new_debuff: Debuff) -> void:
	debuff = new_debuff
	
	debuff.set_debuff_panel(self)
	
	if debuff.is_unlimited_uses():
		$UnlimitedPanel.show()
	
func get_debuff() -> Debuff:
	return debuff
	
## Same text size as every other status box (BuffPanel: 12), smaller only when a
## long one ("Vulnerable 12") wouldn't fit the box.
const FONT_SIZE := 12
const MIN_FONT_SIZE := 8

func set_text(new_text: String) -> void:
	var label: RichTextLabel = $DebuffText
	label.set_text("[center][b]%s[/b][/center]" % new_text)
	var font: Font = label.get_theme_font("bold_font")
	var font_size := FONT_SIZE
	while font_size > MIN_FONT_SIZE and font.get_string_size(new_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > WIDTH - 4:
		font_size -= 1
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_font_size_override("normal_font_size", font_size)

func update_text() -> void:
	set_text(debuff.get_debuff_name())

## The description shows while the pointer is over the box (desktop) and while
## it's pressed (mobile taps, which have no hover). Not while a button is held,
## so dragging a card across the box doesn't pop it up.
var _showing_description: bool = false

func _on_gui_input(event):
	if event.is_action_pressed("select"):
		_show_description()
	elif event.is_action_released("select"):
		_hide_description()

func _on_mouse_entered() -> void:
	if not Input.is_action_pressed("select"):
		_show_description()

func _show_description() -> void:
	if debuff == null or center_description == null:
		return
	center_description.set_text(debuff.get_debuff_name(), debuff.get_debuff_description())
	center_description.set_color(modulate)
	center_description.show()
	_showing_description = true

## Only hides what this box showed (another box may have taken over since).
func _hide_description() -> void:
	if _showing_description and is_instance_valid(center_description):
		center_description.hide()
	_showing_description = false

## Lit up while a hovered card's damage preview uses this debuff.
var _pulse: Tween = null

func set_highlighted(highlighted: bool) -> void:
	modulate = HighlightPulse.GLOW if highlighted else Color("b72e31")
	_pulse = HighlightPulse.set_pulsing(self, _pulse, highlighted)
