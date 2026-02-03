extends Control

var player_image_file_path: String = "res://Assets/Textures/grim.png"

@onready var dialog_panel_top: DialogPanel = $"../EnemyDialogPanel"
@onready var dialog_panel_bottom: DialogPanel = $"../PlayerDialogPanel"
@onready var blur: ColorRect = $Blur

enum PanelPosition {
	Top,
	Bottom
}

@onready var dialog_by_position = {
	PanelPosition.Top: dialog_panel_top,
	PanelPosition.Bottom: dialog_panel_bottom
} 

var step_index: int = 0
var speaking: bool = false
var accepted_tutorial: bool = false

@export var active: bool = false

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
	dialog_panel_top.set_visible(is_active)
	dialog_panel_bottom.set_visible(is_active)
	
func say(text: String, panel_position: PanelPosition) -> bool:
	speaking = true
	var dialog_panel: DialogPanel = dialog_by_position[panel_position]
	dialog_panel.enable_blink_next_icon(false)
	dialog_panel.show()
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
	await say("[b]Excellent! My name is Grim. Like THE Grim Reaper. I'm a pretty big deal. My job is to make sure everyone on this list dies. \n*Shows List*[/b]", PanelPosition.Top)
	
func step_2() -> void:
	set_blur_position(0.475, 0.62)
	set_blur_scale(0.48,0.295)
	
	await say("[b]The way I end lives is by using these cards. It's like a TCG but instead of a game, it's life or death - but mainly death. Neat huh?", PanelPosition.Top)

func step_3() -> void:
	blur.hide()

	await say("[b]Hover over the cards to see what they do.[/b]", PanelPosition.Top)

	
func show_next_step() -> void:
	call('step_%d' %  step_index)
	step_index += 1
	
func _input(event):
	if event.is_action_pressed("skip_dialog") and not speaking and accepted_tutorial:
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
