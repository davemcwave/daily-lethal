extends ColorRect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func clear_cards() -> void:
	for child in $GridContainer.get_children():
		child.queue_free()
		
func populate_cards() -> void:
	clear_cards()
	for child in discard_panel.get_cards():
		var new_card_scene_file_path = child.get_scene_file_path()
		var new_card: Card = load(new_card_scene_file_path).instantiate()
		new_card.set_state(Card.State.Discarded)
		new_card.z_index = 1
		new_card.normalize_saturation()
		$GridContainer.add_child(new_card)
		
	
func _on_button_exit_pressed():
	hide()
