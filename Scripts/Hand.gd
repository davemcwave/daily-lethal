extends HBoxContainer
class_name Hand

const STARTING_INDEX_POSITION = Vector2(8.0, 425.0)
const X_POSITION_GAP = 30.0
@onready var energy = get_tree().get_root().get_node("Scene/Energy")
@onready var deck = get_tree().get_root().get_node("Scene/Deck")


func has_playable_cards() -> bool:
	var energy_left: int = energy.get_energy_amount()
	
	for card: Card in get_children():
		if card.get_energy_cost() <= energy_left:
			return true
	return false
	
func get_right_most_card() -> Card:
	var right_most_card: Card = null
	var right_most_x_value: float = -INF
	for card: Card in get_children():
		if card.global_position.x > right_most_x_value and not card.is_playing():
			right_most_x_value = card.global_position.x
			right_most_card = card
	return right_most_card
	
func get_cards() -> Array[Node]:
	return get_children()

func add_card(card: Card) -> void:
	card.hide()
	add_child(card)
	# wait one idle frame so all Controls and Node2Ds have real global positions
	#await get_tree().process_frame
	
	#var new_global_position = STARTING_INDEX_POSITION
	
	var tween = get_tree().create_tween()
	card.scale = Vector2.ONE*0.1
	card.show()
	#tween.parallel().tween_property(card, "global_position", end_global_position, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
