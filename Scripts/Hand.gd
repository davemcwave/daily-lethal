extends Node2D
class_name Hand

@onready var energy = get_tree().get_root().get_node("Scene/Energy")

func reset_view() -> void:
	print("reset view...")
	for card: Card in get_children():
		card.move_to_front()

func has_playable_cards() -> bool:
	var energy_left: int = energy.get_energy_amount()
	
	for card: Card in get_children():
		if card.get_energy_cost() <= energy_left:
			return true
	return false
