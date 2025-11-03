extends Button
class_name PlayPuzzleButton

@export_file("*.scn") var puzzle_scene
@export var next_buttons: Array[PlayPuzzleButton] = []
@onready var enemy_icon = $EnemyIcon
@onready var background = $"/root/Background"

func _ready() -> void:
	var puzzle: Puzzle = load(puzzle_scene).instantiate()
	var puzzle_icon: Texture2D = puzzle.get_enemy_icon_texture()
	enemy_icon.set_texture(puzzle_icon)
	
	connect("pressed", self._on_button_pressed)

func appear(duration: float = 0.25) -> bool:
	var tween = get_tree().create_tween()
	modulate.a = 0.0
	scale = Vector2(0, 0)
	show()
	tween.parallel().tween_property(self, 'scale', Vector2(1.0,1.0), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await tween.finished
	return true
	
func _on_button_pressed() -> void:
	background.set_puzzle_scene(puzzle_scene)
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")

func get_next_buttons() -> Array[PlayPuzzleButton]:
	return next_buttons
