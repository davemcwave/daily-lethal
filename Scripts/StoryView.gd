extends Control

@onready var play_puzzle_buttons = $PlayPuzzleButtons
@export var current_puzzle_buttons: Array[PlayPuzzleButton]
@onready var puzzle_button_line_connector = $PuzzleButtonLineConnector
@onready var audio_handler = $"/root/AudioHandler"
@onready var background = $"/root/Background"
@onready var puzzle_description_panel = $PuzzleDescriptionPanel
@export var show_all: bool = false

func _ready() -> void:
	if not show_all:
		hide_puzzle_buttons()

	setup_description_panel()
	background.set_from_story_view(true)
	call_deferred('set_completed_colors')
	await show_progression()

func setup_description_panel() -> void:
	if puzzle_description_panel:
		puzzle_description_panel.hide()
		for button: PlayPuzzleButton in play_puzzle_buttons.get_children():
			button.set_description_panel(puzzle_description_panel)

func hide_puzzle_buttons() -> void:
	for play_puzzle_button: PlayPuzzleButton in play_puzzle_buttons.get_children():
		play_puzzle_button.hide()

func get_puzzle_button_map() -> Dictionary:
	var button_map := {}
	for button: PlayPuzzleButton in play_puzzle_buttons.get_children():
		button_map[button.puzzle_scene] = button
	return button_map

func set_completed_colors() -> void:
	for play_puzzle_button: PlayPuzzleButton in play_puzzle_buttons.get_children():
		if play_puzzle_button.is_completed():
			play_puzzle_button.set_self_modulate(Color.GREEN)
func get_buttons_to_show() -> Array[PlayPuzzleButton]:
	var completed_puzzles = background.get_completed_story_puzzles()
	var button_map = get_puzzle_button_map()
	var buttons_to_show: Array[PlayPuzzleButton] = []
	var processed_buttons: Array[PlayPuzzleButton] = []

	# Start with initial buttons
	for button in current_puzzle_buttons:
		if button not in buttons_to_show:
			buttons_to_show.append(button)

	# For each completed puzzle, add its next_buttons
	for puzzle_path in completed_puzzles:
		if button_map.has(puzzle_path):
			var completed_button: PlayPuzzleButton = button_map[puzzle_path]
			if completed_button not in buttons_to_show:
				buttons_to_show.append(completed_button)
			for next_button in completed_button.get_next_buttons():
				if next_button not in buttons_to_show:
					buttons_to_show.append(next_button)

	return buttons_to_show

func show_progression() -> void:
	var buttons_to_show = get_buttons_to_show()
	var completed_puzzles = background.get_completed_story_puzzles()
	var last_completed = background.get_last_completed_story_puzzle()
	var button_map = get_puzzle_button_map()

	# Find newly unlocked buttons (next_buttons of the last completed puzzle)
	var newly_unlocked: Array[PlayPuzzleButton] = []
	if not last_completed.is_empty() and button_map.has(last_completed):
		var last_completed_button: PlayPuzzleButton = button_map[last_completed]
		for next_button in last_completed_button.get_next_buttons():
			if next_button in buttons_to_show:
				newly_unlocked.append(next_button)

	# Show all buttons except newly unlocked ones (those will animate)
	for button in buttons_to_show:
		var is_newly_unlocked = button in newly_unlocked
		if not is_newly_unlocked:
			button.show()
			button.modulate.a = 1.0
			#await button.appear(0.05)
			button.scale = Vector2(1.0, 1.0)

	# Animate newly unlocked buttons
	if newly_unlocked.size() > 0:
		await get_tree().create_timer(0.3).timeout
		for button in newly_unlocked:
			audio_handler.play_sfx("DrawSFX")
			audio_handler.increase_pitch_scale("DrawSFX", 0.05)
			await button.appear(0.15)
			puzzle_button_line_connector.queue_redraw()
		audio_handler.reset_pitch_scale("DrawSFX")
		
	puzzle_button_line_connector.queue_redraw()

	background.clear_last_completed_story_puzzle()

func show_next_puzzle_buttons() -> bool:
	var next_puzzle_buttons: Array[PlayPuzzleButton] = []
	for puzzle_button: PlayPuzzleButton in current_puzzle_buttons:
		audio_handler.play_sfx("DrawSFX")
		audio_handler.increase_pitch_scale("DrawSFX", 0.05)
		await puzzle_button.appear(0.1)
		next_puzzle_buttons.append_array(puzzle_button.get_next_buttons())

	if next_puzzle_buttons.is_empty():
		return false

	current_puzzle_buttons.clear()
	current_puzzle_buttons.append_array(next_puzzle_buttons)
	return true

func animate_all_puzzle_buttons() -> void:
	var can_show_puzzle_buttons: bool = true
	while can_show_puzzle_buttons:
		can_show_puzzle_buttons = await show_next_puzzle_buttons()
		await get_tree().create_timer(0.1).timeout
		puzzle_button_line_connector.queue_redraw()

	audio_handler.reset_pitch_scale("DrawSFX")


func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
