extends Button
class_name CardSelectButton

var card: Card = null

func show_lock_icon() -> void:
	$LockIcon.show()
	
func get_card() -> Card:
	return card
	
func set_card(new_card: Card) -> void:
	card = new_card
	
	set_text(card.get_card_name())
	set("theme_override_colors/font_color", card.get_background_color())
	
	if card.is_permanent_card():
		show_lock_icon()
