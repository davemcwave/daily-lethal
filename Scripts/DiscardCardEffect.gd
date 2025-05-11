extends CardEffect
class_name DiscardCardEffect

@export var max_discard_amount: int = 2
@onready var discard_choose_area: DiscardChooseArea = get_tree().get_root().get_node('Scene/CanvasLayer/DiscardChooseArea')
	
func apply() -> void:
	discard_choose_area.activate_with_max_discard_amount(max_discard_amount)
	await discard_choose_area.closed
	emit_signal("player_input_finished")
