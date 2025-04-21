extends Panel


func _on_gui_input(event):
	if (event.is_action_pressed("select") or event is InputEventScreenTouch) and event.is_pressed():
		$Card.show()
	elif (event.is_action_released("select") or event is InputEventScreenTouch) and not event.is_pressed():
		$Card.hide()
