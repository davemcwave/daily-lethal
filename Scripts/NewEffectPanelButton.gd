extends Button



func _on_pressed():
	var card_effect_buttons_container = load("res://Scenes/CardEffectButtonsContainer.scn").instantiate()
	var index = get_index()
	get_parent().add_child(card_effect_buttons_container)
	get_parent().move_child(card_effect_buttons_container, index)
	queue_free()
