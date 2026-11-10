extends Control

const CHOICE_ICON_BUTTON_OFFSET = Vector2(-40.0, 10.0)
const OPTIONS_PANEL_SCENE = preload("res://Scenes/OptionsPanel.tscn")

@onready var buttons: Array[Button] = [$TutorialButton, $PlayButton, $CardLabButton, $DiscordButton, $OptionsButton]
@onready var choice_icon: TextureRect = $ChoiceIcon
@onready var audio_handler = $"/root/AudioHandler"

var options_panel: Control = null

func _ready() -> void:
	if not $"/root/Background".card_lab_available():
		_hide_card_lab_button()
	for button: Button in buttons:
		button.connect('mouse_entered', _on_button_mouse_entered.bind(button))
		button.connect('mouse_exited', _on_button_mouse_exited.bind(button))

	_on_button_mouse_entered($TutorialButton)

## No Card Lab on phones (see Background.card_lab_available): drop the button and
## move the buttons below it up into its place.
func _hide_card_lab_button() -> void:
	var lab: Button = $CardLabButton
	var at := buttons.find(lab)
	var gap: float = buttons[at + 1].position.y - lab.position.y
	for i in range(at + 1, buttons.size()):
		buttons[i].position.y -= gap
	lab.visible = false
	buttons.erase(lab)

func _on_button_mouse_entered(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text('[b]%s[/b]' % button_label.get_text())
	choice_icon.set_global_position(button.get_global_position() + CHOICE_ICON_BUTTON_OFFSET)
	audio_handler.play_sfx('HitSFX', 0.75, -15)

func _on_button_mouse_exited(button: Button) -> void:
	var button_label: RichTextLabel = button.get_node('Text')
	button_label.set_text(button_label.get_text().replace("[b]", "").replace("[/b]", ""))

func _on_tutorial_button_pressed():
	$"/root/Background".set_show_tutorial(true)
	$"/root/Background".set_from_story_view(true)
	$"/root/Background".set_puzzle_scene("res://Scenes/Puzzles/Tutorial-Puzzle.tscn")
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.tscn")


func _on_play_button_pressed():
	$"/root/Background".set_show_tutorial(false)
	get_tree().change_scene_to_file("res://Scenes/StoryView.tscn")


func _on_card_lab_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Builder/CardBuilder.tscn")


func _on_discord_button_pressed():
	OS.shell_open("https://discord.gg/2sev8HA9sd")


func _on_options_button_pressed():
	if options_panel != null:
		return

	options_panel = OPTIONS_PANEL_SCENE.instantiate()
	options_panel.closed.connect(_on_options_panel_closed)
	add_child(options_panel)

func _on_options_panel_closed() -> void:
	options_panel = null
