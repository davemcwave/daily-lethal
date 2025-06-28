extends TextureRect
class_name DiscardPanel

signal updated

@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")
@onready var discard_count_text: RichTextLabel = $DiscardCount/Text
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for child in get_children():
		if child is Card:
			cards.append(child)
	return cards
	
func get_card_count() -> int:
	return get_cards().size()
	
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
		
	update_discard_count()
		
	return cards_taken

func update_discard_count() -> void:
	await get_tree().create_timer(0.05).timeout
	discard_count_text.set_text("[right][b]%d[/b][/right]" % get_card_count())

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
	#print_order()
	update_discard_count()
		
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


func _on_discard_count_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Discard Pile", "Contains discarded cards")
		center_description.set_color(Color.DIM_GRAY)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
