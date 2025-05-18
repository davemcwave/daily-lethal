extends Panel
class_name DebuffPanel

@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
var debuff: Debuff

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
	
func set_text(new_text: String) -> void:
	$DebuffText.set_text("[center][b]%s[/b][/center]" % new_text)

func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text(debuff.get_debuff_name(), debuff.get_debuff_description())
		center_description.set_color(modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
