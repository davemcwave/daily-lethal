extends Control

@onready var play_puzzle_buttons = $PlayPuzzleButtons
@export var current_puzzle_buttons: Array[PlayPuzzleButton]
@onready var puzzle_button_line_connector = $PuzzleButtonLineConnector

func _ready() -> void:
	hide_puzzle_buttons()
	
func hide_puzzle_buttons() -> void:
	for play_puzzle_button: PlayPuzzleButton in play_puzzle_buttons.get_children():
		play_puzzle_button.hide()

func show_next_puzzle_buttons() -> bool:
	var next_puzzle_buttons: Array[PlayPuzzleButton] = []
	for puzzle_button: PlayPuzzleButton in current_puzzle_buttons:
		await puzzle_button.appear()
		next_puzzle_buttons.append_array(puzzle_button.get_next_buttons())

	current_puzzle_buttons.clear()
	current_puzzle_buttons.append_array(next_puzzle_buttons)
	return true
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		await show_next_puzzle_buttons()
		puzzle_button_line_connector.queue_redraw()
		
