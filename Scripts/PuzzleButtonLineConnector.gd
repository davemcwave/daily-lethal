extends Node2D

@onready var play_puzzle_buttons_node = $"../PlayPuzzleButtons"
@export var line_color: Color = Color.BLACK
@export var line_width: float = 5

func _draw():
	for current_button: PlayPuzzleButton in play_puzzle_buttons_node.get_children():
		for next_button: PlayPuzzleButton in current_button.get_next_buttons():
	
			if not next_button.visible or not current_button.visible or current_button == next_button:
				continue
			else:
				var position_center: Vector2 = current_button.get_node('EnemyIcon').global_position + current_button.get_node('EnemyIcon').size / 2
				var next_button_position_center:  Vector2 = next_button.get_node('EnemyIcon').global_position + next_button.get_node('EnemyIcon').size / 2
				draw_line(position_center, next_button_position_center, line_color, line_width, true)
		
