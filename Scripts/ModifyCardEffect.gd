extends CardEffect
class_name ModifyCardEffect

@onready var discard_pile: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")
@onready var hand: Hand = get_tree().get_root().get_node("Scene/Hand")
	
