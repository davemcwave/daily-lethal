extends TextureRect
class_name DiscardPanel

@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for child in get_children():
		if child is Card:
			cards.append(child)
	return cards
	
func is_empty() -> bool:
	return get_cards().size() == 0

func take_cards(amount: int = 1) -> Array[Card]:
	if get_cards().size() <= 0:
		return []
		
	var cards_taken: Array[Card] = []
	var cards: Array[Card] = get_cards()
	cards.reverse()
	
	for i in range(min(cards.size(), amount)):
		var card: Card = cards[i]
		remove_child(card)
		cards_taken.append(card)
		
	return cards_taken

func add_card(new_card: Card) -> void:
	var new_card_original_postion: Vector2 = new_card.global_position
	new_card.get_parent().remove_child(new_card)
	new_card.z_index = 0
	new_card.z_as_relative = true
	add_child(new_card)
	#queue_redraw()
	new_card.calculate_pivot_offset()
	new_card.reduce_saturation()
	new_card.global_position = new_card_original_postion
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(new_card, "rotation_degrees", rotation_degrees + randf_range(-25, 15), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "global_position:x", global_position.x + randf_range(-5, 20), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "global_position:y", global_position.y + randf_range(-10, 10), 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "scale", Vector2.ONE*0.75, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	buffs_container.activate_on_discard_buffs()
	#await tween.finished
	#if get_child_count() > 0 and $DiscardCenterText.visible:
		#$DiscardCenterText.hide()
		#$DiscardOutsideText.show()
	print_order()
		
func print_order() -> void:
	var card_index: int = 0
	for child in get_children():
		if not (child is Card):
			continue
		
		var card: Card = child
		print("%d: %s" % [card_index, card.card_name])
		card_index += 1
		
func get_last_card() -> Card:
	return get_children().back()
