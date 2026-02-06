extends Button
class_name PlayPuzzleButton

@export_file("*.scn") var puzzle_scene
@export var next_buttons: Array[PlayPuzzleButton] = []
@onready var enemy_icon = $EnemyIcon
@onready var difficulty_container = $DifficultyContainer
@onready var difficulty_icon = $DifficultyContainer/DifficultyIcon
@onready var background = $"/root/Background"
var puzzle: Puzzle = null
var description_panel = null

func _ready() -> void:
	puzzle = load(puzzle_scene).instantiate()
	var puzzle_icon: Texture2D = puzzle.get_enemy_icon_texture()
	enemy_icon.set_texture(puzzle_icon)

	setup_difficulty_icons()
	connect("pressed", self._on_button_pressed)
	connect("mouse_entered", self._on_mouse_entered)
	connect("mouse_exited", self._on_mouse_exited)

func set_description_panel(panel) -> void:
	description_panel = panel

func _on_mouse_entered() -> void:
	if description_panel and is_visible():
		description_panel.populate(puzzle.get_enemy_name(), puzzle.get_enemy_icon_texture())
		var center_pos = get_viewport_rect().size / 2 - description_panel.size / 2
		description_panel.show_at_position(center_pos)

func _on_mouse_exited() -> void:
	if description_panel:
		description_panel.hide()

func setup_difficulty_icons() -> void:
	if not difficulty_container or not difficulty_icon:
		return

	var difficulty: int = background.get_difficulty_for_enemy(puzzle.get_enemy_name())
	# VERY_EASY=0 -> 1 icon, EASY=1 -> 2 icons, MEDIUM=2 -> 3 icons, HARD=3 -> 4 icons, VERY_HARD=4 -> 5 icons
	var icon_count: int = difficulty + 1

	# First icon is already there, add more if needed
	for i in range(icon_count - 1):
		var new_icon = difficulty_icon.duplicate()
		difficulty_container.add_child(new_icon)

func is_completed() -> bool:
	return background.is_story_puzzle_completed(puzzle_scene)

func get_enemy_name() -> String:
	return puzzle.get_enemy_name()
	
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
	background.set_from_story_view(true)
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")

func get_next_buttons() -> Array[PlayPuzzleButton]:
	return next_buttons
