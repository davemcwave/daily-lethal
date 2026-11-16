extends Control
class_name CardCreator

var card_scenes: Array = []
var cards: Array[Card] = []

func set_card_scenes(new_card_scenes: Array) -> void:
	card_scenes = new_card_scenes
	
	remove_all_cards()
	
	for card_scene in card_scenes:
		var card: Card = card_scene.instantiate()
		if card_scene is CustomCardScene:
			card.set_meta("custom_card_scene", card_scene)  # copies are made from it again
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
			# A custom card is made again from its definition (its effects aren't part of a scene).
			var copy: Card = card.get_meta("custom_card_scene").instantiate() if card.has_meta("custom_card_scene") 				else card.duplicate(DUPLICATE_USE_INSTANTIATION)
			# `id` is only assigned in _ready(), so carry the source id over until the
			# copy enters the tree; callers use it to find which option was picked.
			copy.set_id(id)
			return copy
			
	return null
