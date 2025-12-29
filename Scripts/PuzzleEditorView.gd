extends Control

func _ready():
	for button: Button in $Cards.get_children():
		button.connect('pressed', self._on_add_remove_card_button_pressed.bind(button))

func _on_add_remove_card_button_pressed(button: Button):
	pass # Replace with function body.
