extends TextureRect

const CARD_HOVERED_COLOR = Color('1bc46d')
const CARD_NORMAL_COLOR = Color.WHITE

var card: Card = null
@onready var play_text: RichTextLabel = $"../PlayText"

func _on_area_2d_area_entered(area):
	if area.get_parent() is Card:
		self_modulate = CARD_HOVERED_COLOR
		card = area.get_parent()
		play_text.show()
		
func _on_area_2d_area_exited(area):
	self_modulate = CARD_NORMAL_COLOR
	card = null
	play_text.hide()
	
func has_card():
	return card != null
	
func get_card() -> Card:
	return card
