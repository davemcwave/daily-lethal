extends Control
class_name CardCreator

var card_scenes: Array = []

func set_card_scenes(new_card_scenes: Array) -> void:
	card_scenes = new_card_scenes

func remove_all_cards() -> void:
	for child in get_children():
		if child is Card:
			child.queue_free()
	
func get_cards() -> Array[Card]:
	remove_all_cards()
	
	var cards: Array[Card] = []
	for card_scene in card_scenes:
		var card: Card = card_scene.instantiate()
		add_child(card)
		cards.append(card)
		
	return cards
