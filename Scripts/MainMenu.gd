extends Control

@onready var buttons: Array[Button] = [$TutorialButton, $PlayButton, $DiscordButton]

func _ready() -> void:
	for button: Button in buttons:
		button.connect('mouse_entered', _on_button_mouse_entered.bind(button))
		button.connect('mouse_exited', _on_button_mouse_exited.bind(button))
		
func _on_button_mouse_entered(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text('[b]%s[/b]' % button_label.get_text())
	
func _on_button_mouse_exited(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text(button_label.get_text().replace("[b]", "").replace("[/b]", ""))
