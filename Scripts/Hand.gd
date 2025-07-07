extends HBoxContainer
class_name Hand

const STARTING_INDEX_POSITION = Vector2(8.0, 425.0)
const X_POSITION_GAP = 30.0
@onready var energy = get_tree().get_root().get_node("Scene/Energy")
@onready var deck = get_tree().get_root().get_node("Scene/Deck")
@onready var original_separation: int = get("theme_override_constants/separation")
enum State {
	Normal,
	Reordering
}
var state = State.Normal

func has_playable_cards() -> bool:
	var energy_left: int = energy.get_energy_amount()
	
	for card: Card in get_children():
		if card.get_energy_cost() <= energy_left:
			return true
	return false

func set_state(new_state: State) -> void:
	state = new_state
	
	match state:
		State.Reordering:
			set_cards_to_reordering(true)
		State.Normal:
			set_cards_to_reordering(false)
			
func set_cards_to_reordering(reorder: bool) -> void:
	for card in get_cards():
		card.set_reordering(reorder)
		
func reorder_cards_by_x_position():
	var sorted_children = get_cards()

	# Sort by global x-position
	sorted_children.sort_custom(_sort_by_x)
	
	print(sorted_children)

	# Move each child to the end and update z_index
	for i in range(sorted_children.size()):
		var child = sorted_children[i]
		move_child(child, i)
		child.z_index = i
		child.set_original_z_index(child.z_index)
		

func _sort_by_x(a, b):
	return a.global_position.x < b.global_position.x


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

#func _input(event):
	#if event.is_action_pressed("test"):
		#print("### CARDS ###")
		#for card: Card in get_cards():
			#print("card_name: %s, card_index: %d" % [card.get_card_name(), card.z_index])
			
