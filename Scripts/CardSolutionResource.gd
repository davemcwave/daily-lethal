extends Resource
class_name CardSolutionResource

@export var card_scenes: Array[PackedScene] = []

func get_card_scenes() -> Array[PackedScene]:
	return card_scenes
