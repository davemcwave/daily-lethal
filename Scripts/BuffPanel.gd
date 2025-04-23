extends Panel
class_name BuffPanel

var buff: Buff

func set_buff(new_buff: Buff) -> void:
	add_child(new_buff)
	buff = new_buff
	
func update_text() -> void:
	$BuffText.set_text("[center][b]%s[/b][/center]" % buff.get_buff_name())
	
func get_buff() -> Buff:
	return buff
