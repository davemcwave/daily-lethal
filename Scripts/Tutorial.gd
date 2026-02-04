extends Control

var player_image_file_path: String = "res://Assets/Textures/grim.png"

@onready var dialog_panel_top: DialogPanel = $"../EnemyDialogPanel"
@onready var dialog_panel_bottom: DialogPanel = $"../PlayerDialogPanel"
@onready var blur: ColorRect = $Blur
@onready var scene: Scene = get_tree().get_root().get_node('Scene')
@onready var background = $"/root/Background"

enum PanelPosition {
	Top,
	Bottom
}

@onready var dialog_by_position = {
	PanelPosition.Top: dialog_panel_top,
	PanelPosition.Bottom: dialog_panel_bottom
} 

@export var step_index: int = 0
var speaking: bool = false
var accepted_tutorial: bool = false
var waiting: bool = false
@onready var active: bool = background.get_show_tutorial()

func _ready():
	show_tutorial(active)
	
	
	dialog_panel_top.set_icon_texture(load(player_image_file_path))
	dialog_panel_top.set_title_text("[b][color=red]Grim[/color][/b]")
	dialog_panel_bottom.set_icon_texture(load(player_image_file_path))
	dialog_panel_bottom.set_title_text("[b][color=red]Grim[/color][/b]")

	if active:
		call_deferred('show_next_step')

func show_tutorial(is_active: bool) -> void:
	set_visible(is_active)

func get_other_dialog_panel(panel_position: PanelPosition) -> DialogPanel:
	if panel_position == PanelPosition.Top:
		return dialog_panel_bottom
	else:
		return dialog_panel_top
		
func say(text: String, panel_position: PanelPosition) -> bool:
	speaking = true
	var dialog_panel: DialogPanel = dialog_by_position[panel_position]
	var other_dialog_panel: DialogPanel = get_other_dialog_panel(panel_position)
	dialog_panel.enable_blink_next_icon(false)
	dialog_panel.show()
	other_dialog_panel.hide()
	await dialog_panel.play_dialog_text(text)
	dialog_panel.enable_blink_next_icon(true)
	speaking = false
	return true

func set_blur_position(x: float, y: float) -> void:
	blur.get_material().set("shader_parameter/mask_position", Vector2(x, y))

func set_blur_scale(x: float, y: float) -> void:
	blur.get_material().set("shader_parameter/mask_scale", Vector2(x,y))


func step_0() -> void:
	set_blur_position(0.5, 0.5)
	set_blur_scale(0.0,0.0)
	await say("[b]Howdy. You must be new around here. Want me to show you the ropes?[/b]", PanelPosition.Top)
	$YesButton.show()
	$NoButton.show()

func step_1() -> void:
	$YesButton.hide()
	$NoButton.hide()
	await say("[b]Excellent! My name is Grim. Like THE Grim Reaper. I'm a pretty big deal. My job is to make sure everyone on this list dies and I need your help. \t*Shows List*[/b]", PanelPosition.Top)
	
func step_2() -> void:
	set_blur_position(0.475, 0.62)
	set_blur_scale(0.48,0.295)
	
	await say("[b]The way I end lives is by using these cards. It's like a card game but instead of a game, it's life or death - but mainly death. Neat huh?", PanelPosition.Top)

func step_3() -> void:
	set_blur_position(0.565, 0.319)
	set_blur_scale(0.195,0.32)
	await say("[b]We need to play these cards in the right order to kill the next person on our list. \nThis creature up here is our next victim.[/b]", PanelPosition.Bottom)

func step_4() -> void:
	set_blur_position(0.565, 0.319)
	set_blur_scale(0.195,0.32)
	await say("[b]If we get this creature's health to 0, it dies. Death is good. The catch is...[/b]", PanelPosition.Bottom)

func step_5() -> void:
	set_blur_position(0.48, 0.529)
	set_blur_scale(0.435,0.445)
	await say("[b][color=red]You only get 1 turn to kill them.[/color]\nYou must play these cards in the perfect order to get the enemy's red health bar to 0.[/b]", PanelPosition.Top)

func step_6() -> void:
	blur.hide()
	await say("[b]The 🗲 symbol is energy. The 🗲 symbol on the card is the cost to play it. The 🗲 symbol in the middle of the screen is how much energy you have.[/b]", PanelPosition.Top)
	
func step_7() -> void:
	blur.hide()
	await say("[b]Hover over a few cards to see what they do.\nDrag the cards upwards, drop to play them.", PanelPosition.Top)
	waiting = true
	await scene.shown_card_preview
	dialog_panel_top.set_visible(false)
	await scene.buff_added
	dialog_panel_top.set_visible(true)
	waiting = false
	show_next_step()
	
func step_8() -> void:
	#waiting = true
	blur.hide()
	await say("[b]Some cards apply their effect instantly, like Slash. Other cards apply status effects, like Echo and Wound.", PanelPosition.Top)
	
func step_9() -> void:
	dialog_panel_top.set_visible(false)
	waiting = true
	blur.hide()
	
	if scene.get_card_count() < 3:
		await scene.card_count_incremented
		
	if scene.get_card_count() < 3:
		await scene.card_count_incremented
		
	step_10()

func step_10() -> void:
	waiting = true
	blur.hide()
	await say("[b]Eh, you know enough. You can learn the rest on the job. Let's start killin'.", PanelPosition.Bottom)
	$PlayButton.show()
	$RestartButton.show()
	
func show_next_step() -> void:
	var func_name = 'step_%d' %  step_index
	if has_method(func_name):
		call(func_name)
		step_index += 1
	
func _input(event):
	if event.is_action_pressed("skip_dialog") and not speaking and accepted_tutorial and not waiting:
		show_next_step()

func _on_yes_button_pressed():
	accepted_tutorial = true
	show_next_step()

func hide_tutorial() -> void:
	hide()
	dialog_panel_top.hide()
	dialog_panel_bottom.hide()

func _on_no_button_pressed():
	hide_tutorial()

func _on_play_button_pressed():
	background.set_show_tutorial(false)
	hide_tutorial()
	var next_puzzle_scene = scene.get_puzzle().get_next_puzzle_scene()
	var background: Background = get_tree().get_root().get_node("/root/Background")
	background.set_puzzle_scene(next_puzzle_scene)
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")


func _on_restart_button_pressed():
	get_tree().reload_current_scene()
