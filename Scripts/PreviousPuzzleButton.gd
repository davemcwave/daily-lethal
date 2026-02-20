extends Button

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var background = $"/root/Background"

const SECONDS_PER_DAY := 24 * 60 * 60

func _ready():
	if background.is_from_story_view():
		hide()
		
func _on_pressed() -> void:
	var previous_puzzle_scene = scene.get_puzzle().get_previous_puzzle_scene()
	
	if is_web_platform():
		var previous_date := ManifestDateHelper.get_previous_date(background.get_puzzle_date())
		if previous_date.is_empty():
			previous_date = _get_previous_daily_puzzle_date(background.get_puzzle_date())
		if previous_date.is_empty() and previous_puzzle_scene != null:
			previous_date = _get_puzzle_date_from_scene(previous_puzzle_scene)
		if previous_date.is_empty():
			return
		var base_url_variant = JavaScriptBridge.eval("window.location.origin", true)
		var base_url = String(base_url_variant)
		if base_url.is_empty():
			base_url = "https://playlethal.fun"
		var device_type = JavaScriptBridge.eval("localStorage.getItem('device_type')", true)
		var desktop = "/desktop" if device_type == "desktop" else ""
		var previous_url = "%s%s/%s" % [base_url, desktop, previous_date]
		open_window_in_same_tab(previous_url)
		return
	
	if previous_puzzle_scene == null:
		return
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

func _get_previous_daily_puzzle_date(current_date: String) -> String:
	if current_date.is_empty():
		return ""
	var parsed := _parse_iso_date_to_datetime_dict(current_date)
	if parsed.is_empty():
		return ""
	var unix_time := Time.get_unix_time_from_datetime_dict(parsed)
	var base_datetime := Time.get_datetime_dict_from_unix_time(unix_time)
	var weekday := int(base_datetime.get("weekday", 1))
	var subtract_days := 3 if weekday == 1 else 1
	var prev_unix := unix_time - SECONDS_PER_DAY * subtract_days
	var prev_datetime := Time.get_datetime_dict_from_unix_time(prev_unix)
	return "%04d-%02d-%02d" % [prev_datetime.year, prev_datetime.month, prev_datetime.day]

func _parse_iso_date_to_datetime_dict(date_str: String) -> Dictionary:
	var parts := date_str.split("-")
	if parts.size() != 3:
		return {}
	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
		"hour": 0,
		"minute": 0,
		"second": 0
	}

func _get_puzzle_date_from_scene(scene_path: String) -> String:
	if scene_path.is_empty():
		return ""
	var previous_puzzle: Puzzle = load(scene_path).instantiate()
	if previous_puzzle == null:
		return ""
	return previous_puzzle.get_puzzle_date()
