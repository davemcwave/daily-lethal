extends ColorRect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
func clear_cards() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
func populate_cards() -> void:
	clear_cards()
	for child in discard_panel.get_cards():
		var new_card: Card = child.duplicate(DUPLICATE_USE_INSTANTIATION)
		new_card.set_state(Card.State.Discarded)
		new_card.z_index = 1
		new_card.normalize_saturation()
		grid_container.add_child(new_card)
		
	
func _on_button_exit_pressed():
	hide()
