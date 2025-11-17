extends Panel

@onready var effects_vbox_container = $VBoxContainer
@onready var add_effect_button = $VBoxContainer/AddEffectButton

func _on_add_effect_button_pressed():
	effects_vbox_container.add_child(load("res://Scenes/EffectPanel.scn").instantiate())
	effects_vbox_container.move_child(add_effect_button, effects_vbox_container.get_child_count()-1)
