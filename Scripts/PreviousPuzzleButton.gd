extends Button

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
func _on_pressed() -> void:
	var previous_puzzle_scene = scene.get_puzzle().get_previous_puzzle_scene()
	if previous_puzzle_scene != null:
		var previous_puzzle: Puzzle = load(previous_puzzle_scene).instantiate()
		var previous_puzzle_date: String = previous_puzzle.get_puzzle_date()
		var base_url = JavaScriptBridge.eval("window.location.origin", true)
		var previous_url = "%s/%s" % [base_url, previous_puzzle_date]
		open_window_in_same_tab(previous_url)

func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
