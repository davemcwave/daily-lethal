extends Button

@onready var scene: Scene = get_tree().get_root().get_node("Scene")

func _on_pressed() -> void:
	var previous_puzzle_scene = scene.get_puzzle().get_previous_puzzle_scene()
	if previous_puzzle_scene == null:
		return
	
	if is_web_platform():
		var previous_puzzle: Puzzle = load(previous_puzzle_scene).instantiate()
		if previous_puzzle == null:
			return
		var previous_puzzle_date: String = previous_puzzle.get_puzzle_date()
		var base_url = JavaScriptBridge.eval("window.location.origin", true)
		var device_type = JavaScriptBridge.eval("localStorage.getItem('device_type')", true)
		var desktop = "/desktop" if device_type == "desktop" else ""
		var previous_url = "%s%s/%s" % [base_url, desktop, previous_puzzle_date]
		open_window_in_same_tab(previous_url)
	else:
		load_puzzle_locally(previous_puzzle_scene)

func is_web_platform() -> bool:
	return Engine.has_singleton("JavaScriptBridge") and OS.has_feature("web")

func load_puzzle_locally(puzzle_scene_path: String) -> void:
	var background: Background = get_tree().get_root().get_node("/root/Background")
	background.set_puzzle_scene(puzzle_scene_path)
	var main_scene_path := "res://Scenes/Scene0.scn" if OS.has_feature("mobile") else "res://Scenes/Scene0Desktop.scn"
	get_tree().change_scene_to_file(main_scene_path)

func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
