extends ColorRect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
func clear_cards() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
func populate_cards() -> void:
	clear_cards()
	remove_all_discard_label()

	
	for child_index in range(discard_panel.get_card_count()):
		var child = discard_panel.get_cards()[child_index]
		var new_card: Card = child.duplicate()
		new_card.set_state(Card.State.Discarded)
		new_card.z_index = 1
		
		#new_card.get_node('IconPane')l.move_child(gradient_background,0)
		new_card.normalize_saturation()
		new_card.set_mouse_filter(Control.MOUSE_FILTER_PASS)
		grid_container.add_child(new_card)
		
		if child_index == 0:
			add_position_label_to_card(new_card, "Bottom of Discard")
		elif child_index == discard_panel.get_card_count() - 1:
			add_position_label_to_card(new_card, "Top of Discard")

func remove_all_discard_label() -> void:
	for card in grid_container.get_children():
		for card_child in card.get_children():
			if card_child is DiscardPileViewText:
				card_child.queue_free()

func add_position_label_to_card(card: Card, text: String) -> void:
	var discard_pile_view_panel_text = load("res://Scenes/DiscardPileViewText.scn").instantiate()
	discard_pile_view_panel_text.set_text(text)
	card.add_child(discard_pile_view_panel_text)
	discard_pile_view_panel_text.set_position(Vector2(3.0, -5.0))
	
func add_bottom_of_discard_label() -> void:
	if grid_container.get_child_count() <= 0:
		return
		
	var discard_pile_view_panel_text = load("res://Scenes/DiscardPileViewText.scn").instantiate()
	discard_pile_view_panel_text.set_text("Bottom of Discard")
	var card_bottom_of_discard = grid_container.get_child(0)
	card_bottom_of_discard.add_child(discard_pile_view_panel_text)
	discard_pile_view_panel_text.set_position(Vector2(3.0, -5.0))
	
func add_top_of_discard_label() -> void:
	if grid_container.get_child_count() <= 0:
		return
		
	var discard_pile_view_panel_text = load("res://Scenes/DiscardPileViewText.scn").instantiate()
	discard_pile_view_panel_text.set_text("Top of Discard")
	var card_top_of_discard = grid_container.get_children().back()
	card_top_of_discard.add_child(discard_pile_view_panel_text)
	discard_pile_view_panel_text.set_position(Vector2(3.0, -5.0))
		
	
func _on_button_exit_pressed():
	hide()
