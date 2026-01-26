extends HBoxContainer
class_name Hand

const STARTING_INDEX_POSITION = Vector2(8.0, 425.0)
const X_POSITION_GAP = 30.0
@export var is_mobile: bool = false
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

func get_card_separation(card_count: int) -> float:
	var target_n =  7 if is_mobile else 12
	var target_sep = -120.0 if is_mobile else -60.0

	if card_count <= 1:
		return 0.0
	return target_sep * float(card_count - 1) / float(target_n - 1)

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
		
func reorder_cards_by_x_position() -> bool:

	# Wait for the next idle frame to ensure positions are updated
	await get_tree().process_frame
	
	var sorted_children = get_cards()
	
	# Sort by global x-position
	sorted_children.sort_custom(_sort_by_x)
	
	#print(sorted_children)

	# Move each child to the end and update z_index
	for i in range(sorted_children.size()):
		var child = sorted_children[i]
		move_child(child, i)
		child.z_index = i
		child.set_original_z_index(child.z_index)
		
	return true

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
	#
	#if card.is_inside_tree() and card.get_parent() != null:
		#card.get_parent().remove_child(card)
		
	add_child(card)
	
	reorder_cards_by_x_position()
	
	card.show()
	card.bounce()
	
		
func reduce_card_separation(pixels: int) -> void:
	set("theme_override_constants/separation", get("theme_override_constants/separation") - pixels)
	

func update_card_separation() -> void:
	set("theme_override_constants/separation", get_card_separation(get_cards().size()))
	

#func _input(event):
	#if event.is_action_pressed("test"):
		#print("### CARDS ###")
		#for card: Card in get_cards():
			#print("card_name: %s, card_index: %d" % [card.get_card_name(), card.z_index])
			
