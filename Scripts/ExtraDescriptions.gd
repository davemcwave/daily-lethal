extends VBoxContainer

func add_description(new_text: String) -> void:
	var extra_description_panel: Panel = load("res://Scenes/ExtraDescriptionPanel.scn").instantiate()
	extra_description_panel.set_text(new_text)
	add_child(extra_description_panel)
