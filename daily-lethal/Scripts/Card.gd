extends Panel

var grabbed: bool = false

func _on_gui_input(event):
	if (event.is_action_pressed("select") or event is InputEventScreenTouch) and event.is_pressed():
		grab()
	elif (event.is_action_released("select") or event is InputEventScreenTouch) and not event.is_pressed():
		drop()

func grab() -> void:
	grabbed = true
	
func drop() -> void:
	grabbed = false

func _process(delta):
	if grabbed:
		global_position = get_global_mouse_position() - size/2
