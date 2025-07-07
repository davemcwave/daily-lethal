extends CheckButton

@onready var scene: Scene = get_tree().get_root().get_node('Scene')
@onready var hand: Hand = scene.get_node('Hand')

func _on_toggled(toggled_on):
	if toggled_on:
		hand.set_state(Hand.State.Reordering)
		$ReoderingLabel.show()
		$ReorderLabel.hide()
	else:
		hand.set_state(Hand.State.Normal)
		$ReorderLabel.show()
		$ReoderingLabel.hide()
	release_focus()
