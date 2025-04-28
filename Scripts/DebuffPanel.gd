extends Panel
class_name DebuffPanel

@onready var buff_preview: BuffPreview = get_tree().get_root().get_node("Scene/CanvasLayer/BuffPreview")
var debuff: Debuff

func blink() -> void:
	var original_color: Color = get_theme_stylebox("panel").bg_color
	get_theme_stylebox("panel").bg_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	get_theme_stylebox("panel").bg_color = original_color
	
	
func set_debuff(new_debuff: Debuff) -> void:
	debuff = new_debuff
	
	debuff.set_debuff_panel(self)
	
func get_debuff() -> Debuff:
	return debuff
	
func set_text(new_text: String) -> void:
	$DebuffText.set_text("[center][b]%s[/b][/center]" % new_text)

func _on_gui_input(event):
	if event.is_action_pressed("select"):
		buff_preview.set_text(debuff.get_debuff_name(), debuff.get_debuff_description())
		buff_preview.set_color(modulate)
		buff_preview.show()
	elif event.is_action_released("select"):
		buff_preview.hide()
