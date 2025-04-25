extends Panel
class_name BuffPanel

@onready var buff_preview: BuffPreview = get_tree().get_root().get_node("Scene/CanvasLayer/BuffPreview")
@export_file("*.scn") var buff_scene
@export var buff: Buff

func _ready():
	if buff_scene != null:
		set_buff(load(buff_scene).instantiate())
	elif buff != null:
		set_buff(buff)
		
func blink() -> void:
	var original_color: Color = get_theme_stylebox("panel").bg_color
	get_theme_stylebox("panel").bg_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	get_theme_stylebox("panel").bg_color = original_color
	
func set_buff(new_buff: Buff) -> void:
	buff = new_buff
	
	if buff.get_parent() != self:
		add_child(new_buff)
	
	buff.set_buff_panel(self)
	
	update_text()
	
func update_text() -> void:
	$BuffText.set_text("[center][b]%s[/b][/center]" % buff.get_buff_name())
	
func get_buff() -> Buff:
	return buff


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		buff_preview.set_text(buff.get_buff_name(), buff.get_buff_description())
		buff_preview.set_color(get_theme_stylebox("panel").bg_color)
		buff_preview.show()
	elif event.is_action_released("select"):
		buff_preview.hide()
