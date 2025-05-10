extends ColorRect

@onready var card_play_area = get_parent().get_node("CardPlayArea")
#func _ready():
	#activate()
	
func activate() -> void:
	card_play_area.set_useable(false)
