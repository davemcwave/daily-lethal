extends CheckButton

@onready var scene: Scene = get_tree().get_root().get_node('Scene')
@onready var hand: Hand = scene.get_node('Hand')
var blink_tween: Tween = null 

func start_blink(node: Control):
	if blink_tween:  # Stop any existing tween
		blink_tween.kill()
	
	blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.tween_property(node, "modulate:a", 0.0, 0.3)
	blink_tween.tween_property(node, "modulate:a", 1.0, 0.3)
	
func stop_blink(node: Control):
	if blink_tween:
		blink_tween.kill()
		blink_tween = null
		node.modulate.a = 1.0
	
func _on_toggled(toggled_on):
	if toggled_on:
		hand.set_state(Hand.State.Reordering)
		$ReorderingLabel.show()
		$ReorderLabel.hide()
		start_blink($ReorderingLabel)
	else:
		hand.set_state(Hand.State.Normal)
		$ReorderLabel.show()
		$ReorderingLabel.hide()
		stop_blink($ReorderingLabel)
	release_focus()
