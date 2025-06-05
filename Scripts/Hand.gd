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
	
func get_cards() -> Array[Node]:
	return get_children()

func get_card_with_id(id: int) -> Card:
	for card: Card in get_cards():
		if card.get_id() == id:
			return card
			
	return null
	
func add_card(card: Card) -> void:
	card.hide()
	add_child(card)
	
	# wait one idle frame so all Controls and Node2Ds have real global positions
	#await get_tree().process_frame
	
	#var new_global_position = STARTING_INDEX_POSITION
	
	#var tween = get_tree().create_tween()
	#card.scale = Vector2.ONE*0.1
	card.show()
	#tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	card.bounce()

func _input(event):
	if event.is_action_pressed("test"):
		print("### CARDS ###")
		for card: Card in get_cards():
			print("card_name: %s, card_index: %d" % [card.get_card_name(), card.z_index])
			
