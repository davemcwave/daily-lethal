extends TextureButton


func _on_pressed():
	get_parent().get_node("BG").show()
	get_parent().get_node("NewAttemptPanel").show()
