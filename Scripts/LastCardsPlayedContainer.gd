extends GridContainer

var index: int = 0

func add_card(card: Card) -> void:
	#rotate_children()
	var card_panel: Panel = get_child(index)
	var card_panel_icon: TextureRect = card_panel.get_node("Icon")
	card_panel_icon.set_texture(card.get_icon_texture())
	card_panel.get_theme_stylebox("panel").bg_color = card.get_background_color() 
	index += 1
	index = index % 3
	
	
func rotate_children():
	var first = get_child(0)
	var third = get_child(2)
	move_child(first, 1)
	move_child(third,0)
	
