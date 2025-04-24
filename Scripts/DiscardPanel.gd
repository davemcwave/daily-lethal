extends TextureRect
class_name DiscardPanel

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for child in get_children():
		if child is Card:
			cards.append(child)
	return cards
	
func add_card(new_card: Card) -> void:
	var new_card_original_postion: Vector2 = new_card.global_position
	new_card.get_parent().remove_child(new_card)
	add_child(new_card)
	new_card.calculate_pivot_offset()
	new_card.reduce_saturation()
	new_card.global_position = new_card_original_postion
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(new_card, "rotation_degrees", rotation_degrees + randf_range(-25, 15), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "global_position:x", global_position.x + randf_range(-5, 20), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "global_position:y", global_position.y + randf_range(-10, 10), 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "scale", Vector2.ONE*0.75, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	#await tween.finished
	#if get_child_count() > 0 and $DiscardCenterText.visible:
		#$DiscardCenterText.hide()
		#$DiscardOutsideText.show()
