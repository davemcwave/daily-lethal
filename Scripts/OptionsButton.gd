extends Button

const OPTIONS_PANEL_SCENE = preload("res://Scenes/OptionsPanel.tscn")

var options_panel = null

func _on_pressed():
	if options_panel != null:
		return

	options_panel = OPTIONS_PANEL_SCENE.instantiate()
	options_panel.closed.connect(_on_options_panel_closed)
	get_parent().get_node('CanvasLayer').add_child(options_panel)
	options_panel.set_global_position(get_viewport_rect().get_center() - get_viewport_rect().size/2)

func _on_options_panel_closed() -> void:
	options_panel = null
