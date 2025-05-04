extends CardEffect
class_name ModifyCardEffect

@onready var hand: Hand = get_tree().get_root().get_node("Scene/Hand")
	
# TO BE OVERWRITTEN
func apply() -> void:
	pass
