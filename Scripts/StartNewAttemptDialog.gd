extends AcceptDialog


func _on_confirmed():
	get_tree().reload_current_scene()


func _on_canceled():
	pass # Replace with function body.
