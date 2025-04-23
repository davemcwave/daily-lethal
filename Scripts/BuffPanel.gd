extends Panel
class_name BuffPanel

var buff: Buff

func blink() -> void:
	var original_color: Color = get_theme_stylebox("panel").bg_color
	get_theme_stylebox("panel").bg_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	get_theme_stylebox("panel").bg_color = original_color
	
func set_buff(new_buff: Buff) -> void:
	add_child(new_buff)
	buff = new_buff
	
	buff.set_buff_panel(self)
	
func update_text() -> void:
	$BuffText.set_text("[center][b]%s[/b][/center]" % buff.get_buff_name())
	
func get_buff() -> Buff:
	return buff
