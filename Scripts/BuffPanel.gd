extends Panel
class_name BuffPanel

@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
@export_file("*.tscn") var buff_scene
@export var buff: Buff
var _blinking: bool = false
var _base_modulate: Color
var _highlighted: bool = false
var _pulse: Tween = null
const HIGHLIGHT_ADJUST: float = 0.2

func _ready():
	_base_modulate = modulate
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_hide_description)
	tree_exiting.connect(_hide_description)
	if buff_scene != null:
		set_buff(load(buff_scene).instantiate())
	elif buff != null:
		set_buff(buff)

func blink() -> void:
	if not visible and get_parent() != null and get_parent().has_method("get_shown_panel"):
		var shown: BuffPanel = get_parent().get_shown_panel(self)
		if shown != self:
			shown.blink()  # this buff is grouped into another box: blink that one
			return
	# don’t read modulate at runtime, you already know your normal
	modulate = Color(1,1,1)      # blink red
	await get_tree().create_timer(0.1).timeout
	_apply_modulate()


	
func set_buff(new_buff: Buff) -> void:
	buff = new_buff
	
	if buff.get_parent() != self:
		if new_buff.get_parent() != null: 
			new_buff.get_parent().remove_child(new_buff)
		add_child(new_buff)
	
	buff.set_buff_panel(self)
	_base_modulate = buff.get_color()
	_apply_modulate()

	if buff.should_show_unlimited_panel():
		$UnlimitedPanel.show()
		#$UnlimitedPanel.get("theme_override_styles/panel").set("bg_color", buff.get_color())
	
	update_text()
	
func update_text() -> void:
	_render_text()
	if get_parent() != null and get_parent().has_method("queue_regroup"):
		get_parent().queue_regroup()  # uses changed: the group's total may too

var _group_count := 1

## Set by BuffsContainer when same-kind buffs share this box: their total.
func set_group_count(count: int) -> void:
	_group_count = count
	_render_text()

func _render_text() -> void:
	var label: String = buff.get_display_name()
	if _group_count > 1:
		label = "%s %d" % [buff.buff_name, _group_count]
	$BuffText.set_text("[center][b]%s[/b][/center]" % label)
	
func get_buff() -> Buff:
	return buff


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
	if buff == null or center_description == null:
		return
	# A grouped box ("Critical 2") describes the group's total.
	var description: String = Buff.fill_x(buff.buff_description, _group_count, buff) if _group_count > 1 else buff.get_buff_description()
	center_description.set_text(buff.get_display_name() if _group_count <= 1 else "%s %d" % [buff.buff_name, _group_count], description)
	center_description.set_color(modulate)
	center_description.show()
	_showing_description = true

## Only hides what this box showed (another box may have taken over since).
func _hide_description() -> void:
	if _showing_description and is_instance_valid(center_description):
		center_description.hide()
	_showing_description = false

func set_highlighted(new_highlighted: bool) -> void:
	if _highlighted == new_highlighted:
		return
	_highlighted = new_highlighted
	_apply_modulate()
	_pulse = HighlightPulse.set_pulsing(self, _pulse, _highlighted)

func _apply_modulate() -> void:
	if _highlighted:
		modulate = HighlightPulse.GLOW  # gold glow: this status will be used
	else:
		modulate = _base_modulate
