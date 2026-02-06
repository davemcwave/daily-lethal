extends Control

const CHOICE_ICON_BUTTON_OFFSET = Vector2(-40.0, 10.0)
const OPTIONS_PANEL_SCENE = preload("res://Scenes/OptionsPanel.tscn")

@onready var buttons: Array[Button] = [$TutorialButton, $PlayButton, $DiscordButton, $OptionsButton]
@onready var choice_icon: TextureRect = $ChoiceIcon
@onready var audio_handler = $"/root/AudioHandler"

var options_panel: Control = null

func _ready() -> void:
	for button: Button in buttons:
		button.connect('mouse_entered', _on_button_mouse_entered.bind(button))
		button.connect('mouse_exited', _on_button_mouse_exited.bind(button))

	_on_button_mouse_entered($TutorialButton)

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
	$"/root/Background".set_puzzle_scene("res://Scenes/Puzzles/Tutorial-Puzzle.scn")
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")


func _on_play_button_pressed():
	$"/root/Background".set_show_tutorial(false)
	get_tree().change_scene_to_file("res://Scenes/StoryView.scn")


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
