extends TextureRect

const CARD_HOVERED_COLOR = Color('1bc46d')
const CARD_NORMAL_COLOR = Color.WHITE

var card: Card = null
@onready var play_text: RichTextLabel = $"../PlayText"
@export var useable: bool = true

func _on_area_2d_area_entered(area):
	if area.get_parent() is Card and card == null and useable:
		self_modulate = CARD_HOVERED_COLOR
		card = area.get_parent()
		play_text.show()
		card.refresh_energy_text()
		
func _on_area_2d_area_exited(area):
	self_modulate = CARD_NORMAL_COLOR
	if card != null:
		card.set_energy_text(card.get_energy_cost())
	card = null
	play_text.hide()
	
func is_useable() -> bool:
	return useable
	
func set_useable(new_useable: bool) -> void:
	useable = new_useable

func has_card():
	return card != null
	
func get_card() -> Card:
	return card
