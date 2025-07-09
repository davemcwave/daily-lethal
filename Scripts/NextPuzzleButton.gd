extends Button

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
func _on_pressed() -> void:
	var next_puzzle_scene = scene.get_puzzle().get_next_puzzle_scene()
	if next_puzzle_scene != null:
		var next_puzzle: Puzzle = load(next_puzzle_scene).instantiate()
		var next_puzzle_date: String = next_puzzle.get_puzzle_date()
		var base_url = JavaScriptBridge.eval("window.location.origin", true)
		var next_url = "%s/%s" % [base_url, next_puzzle_date]
		open_window_in_same_tab(next_url)

func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
