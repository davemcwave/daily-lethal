extends Panel
class_name BuffPanel

@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
@export_file("*.scn") var buff_scene
@export var buff: Buff
var _blinking: bool = false
var _base_modulate: Color
var _highlighted: bool = false
const HIGHLIGHT_ADJUST: float = 0.2

func _ready():
	_base_modulate = modulate
	if buff_scene != null:
		set_buff(load(buff_scene).instantiate())
	elif buff != null:
		set_buff(buff)

func blink() -> void:
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
	$BuffText.set_text("[center][b]%s[/b][/center]" % buff.get_buff_name())
	
func get_buff() -> Buff:
	return buff


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text(buff.get_buff_name(), buff.get_buff_description())
		center_description.set_color(modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()

func set_highlighted(new_highlighted: bool) -> void:
	if _highlighted == new_highlighted:
		return
	_highlighted = new_highlighted
	_apply_modulate()

func _apply_modulate() -> void:
	if _highlighted:
		var r = clamp(_base_modulate.r + HIGHLIGHT_ADJUST, 0.0, 1.0)
		var g = clamp(_base_modulate.g + HIGHLIGHT_ADJUST, 0.0, 1.0)
		var b = clamp(_base_modulate.b + HIGHLIGHT_ADJUST, 0.0, 1.0)
		modulate = Color(r, g, b, _base_modulate.a)
	else:
		modulate = _base_modulate
