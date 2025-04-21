extends Node2D
class_name Hand

func reset_view() -> void:
	print("reset view...")
	for card: Card in get_children():
		card.move_to_front()
