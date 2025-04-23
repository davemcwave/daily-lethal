extends Panel


func _on_button_confirm_pressed():
	get_tree().reload_current_scene()


func _on_button_exit_pressed():
	get_parent().get_node("BG").hide()
	hide()
