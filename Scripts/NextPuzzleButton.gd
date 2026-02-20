extends Button

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var background = $"/root/Background"

func _ready():
	if background.is_from_story_view():
		hide()
		
		
func _on_pressed() -> void:
	var next_puzzle_scene = scene.get_puzzle().get_next_puzzle_scene()
	if next_puzzle_scene == null:
		return
	
	if is_web_platform():
		var next_date := ManifestDateHelper.get_next_date(background.get_puzzle_date())
		if next_date.is_empty():
			var next_puzzle: Puzzle = load(next_puzzle_scene).instantiate()
			if next_puzzle != null:
				next_date = next_puzzle.get_puzzle_date()
		if next_date.is_empty():
			return
		var base_url_variant = JavaScriptBridge.eval("window.location.origin", true)
		var base_url = String(base_url_variant)
		if base_url.is_empty():
			base_url = "https://playlethal.fun"
		var device_type = JavaScriptBridge.eval("localStorage.getItem('device_type')", true)
		var desktop = "/desktop" if device_type == "desktop" else ""
		var next_url = "%s%s/%s" % [base_url, desktop, next_date]
		open_window_in_same_tab(next_url)
	else:
		load_puzzle_locally(next_puzzle_scene)

func is_web_platform() -> bool:
	return Engine.has_singleton("JavaScriptBridge") and OS.has_feature("web")

func load_puzzle_locally(puzzle_scene_path: String) -> void:
	var background: Background = get_tree().get_root().get_node("/root/Background")
	background.set_puzzle_scene(puzzle_scene_path)
	var main_scene_path := "res://Scenes/Scene0.scn" if OS.has_feature("mobile") else "res://Scenes/Scene0Desktop.scn"
	get_tree().change_scene_to_file(main_scene_path)

func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
