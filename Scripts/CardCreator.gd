extends Control
class_name CardCreator

var card_scenes: Array = []
var cards: Array[Card] = []

func set_card_scenes(new_card_scenes: Array) -> void:
	card_scenes = new_card_scenes
	
	remove_all_cards()
	
	for card_scene in card_scenes:
		var card: Card = card_scene.instantiate()
		add_child(card)
		card.hide()
		cards.append(card)

func remove_all_cards() -> void:
	cards.clear()
	
	for child in get_children():
		if child is Card:
			child.queue_free()

func get_cards() -> Array[Card]:
	return cards
	
func get_card_with_id(id: int) -> Card:
	for card: Card in get_cards():
		if card.get_id() == id:
			return card.duplicate(DUPLICATE_USE_INSTANTIATION)
			
	return null
