extends Resource
class_name CardSolutionResource

@export var card_scenes: Array[PackedScene] = []
@export var hand_indices: Array[int] = []

func get_card_scenes() -> Array[PackedScene]:
	return card_scenes

func get_hand_indices() -> Array[int]:
	return hand_indices
