extends Control

var share_text_template = "💀 I defeated the {enemy_name} in {attempt_count} attempt{attempt_plural}!\n🃏 My solution: {best_card_count} cards\nPlay puzzle 👉 {puzzle_url}" # https://playlethal.fun"
var share_text = ""
const SECONDS_PER_DAY := 24 * 60 * 60
@onready var background = get_node("/root/Background")
func _ready():
	var attempt_plural: String = '' if background.attempts <= 1 else 's'
	var share_url = get_share_url()
	share_text = share_text_template.format(
		{
			'enemy_name': background.enemy_name,
			'attempt_plural': attempt_plural,
			'attempt_count': background.attempts,
			'best_card_count': background.best_card_count,
			'puzzle_url': share_url,
		}
	)

	$VBoxContainer/AttemptText.set_text("[center][b]IN [color=green]%d[/color] ATTEMPT%s[/b][/center]" % [background.attempts, attempt_plural.to_upper()])
	$VBoxContainer/BestAttemptText.set_text("[center][b]WITH [color=gold]%d[/color] CARDS PLAYED[/b][/center]" % background.best_card_count)
	$EnemyIcon.set_texture(background.get_enemy_texture())

	if not background.is_test_puzzle() or not background.get_puzzle_date().is_empty():
		background.mark_puzzle_completed(background.get_puzzle_date())
	background.save_played_cards_solution()

	if background.is_from_story_view():
		background.mark_story_puzzle_completed(background.get_puzzle_scene())

func get_share_url() -> String:
	var base_url := "https://playlethal.fun"
	var puzzle_date: String = background.get_puzzle_date()
	if puzzle_date.is_empty():
		return base_url
	return "%s/%s" % [base_url, puzzle_date]

func _on_play_again_button_pressed():
	var should_use_desktop_layout = background.is_using_desktop_layout()
	background.clear()
	
	if is_web_platform():
		var next_scene_path := "res://Scenes/Scene0Desktop.scn" if should_use_desktop_layout else "res://Scenes/Scene0.scn"
		get_tree().change_scene_to_file(next_scene_path)
	else:
		change_to_main_scene()

func _on_share_button_pressed():
	DisplayServer.clipboard_set(share_text)
	$ShareButton/TextureRect.hide()
	$ShareButton.set_text("   COPIED!")
	$ShareButton.set_disabled(true)
	await get_tree().create_timer(1.5).timeout
	$ShareButton.set_disabled(false)
	$ShareButton.set_text("   SHARE")
	$ShareButton/TextureRect.show()

func _on_get_tomorrow_button_pressed():
	if background.is_from_story_view():
		background.clear()
		get_tree().change_scene_to_file("res://Scenes/StoryView.scn")
		return

	var next_puzzle_scene = background.get_next_puzzle_scene()
	background.clear()

	if is_web_platform():
		var target_date := ManifestDateHelper.get_next_date(background.get_puzzle_date())
		if target_date.is_empty() and next_puzzle_scene != null:
			target_date = _get_next_puzzle_date_from_scene(next_puzzle_scene)
		if target_date.is_empty():
			target_date = _get_next_daily_puzzle_date(background.get_puzzle_date())
		if target_date.is_empty():
			OS.shell_open("https://playlethal.beehiiv.com/subscribe")
			return
		var base_url_variant = JavaScriptBridge.eval("window.location.origin", true)
		var base_url = String(base_url_variant)
		if base_url.is_empty():
			base_url = "https://playlethal.fun"
		var device_type = JavaScriptBridge.eval("localStorage.getItem('device_type')", true)
		var desktop = "/desktop" if device_type == "desktop" else ""
		var next_url = "%s%s/%s" % [base_url, desktop, target_date]
		open_window_in_same_tab(next_url)
		return

	if next_puzzle_scene == null:
		OS.shell_open("https://playlethal.beehiiv.com/subscribe")
	else:
		background.set_puzzle_scene(next_puzzle_scene)
		change_to_main_scene()

func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)


func _on_no_thanks_button_pressed() -> void:
	$Overlay.queue_free()

func is_web_platform() -> bool:
	return Engine.has_singleton("JavaScriptBridge") and OS.has_feature("web")

func change_to_main_scene() -> void:
	var main_scene_path := "res://Scenes/Scene0.scn" if OS.has_feature("mobile") else "res://Scenes/Scene0Desktop.scn"
	get_tree().change_scene_to_file(main_scene_path)

func _get_next_daily_puzzle_date(current_date: String) -> String:
	if current_date.is_empty():
		return ""
	var parsed_date := _parse_iso_date_to_datetime_dict(current_date)
	if parsed_date.is_empty():
		return ""
	var unix_time := Time.get_unix_time_from_datetime_dict(parsed_date)
	var base_datetime := Time.get_datetime_dict_from_unix_time(unix_time)
	var weekday := int(base_datetime.get("weekday", 0))
	var add_days := 3 if weekday == 5 else 1
	var next_unix := unix_time + SECONDS_PER_DAY * add_days
	var next_datetime := Time.get_datetime_dict_from_unix_time(next_unix)
	return "%04d-%02d-%02d" % [next_datetime.year, next_datetime.month, next_datetime.day]

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

func _get_next_puzzle_date_from_scene(scene_path: String) -> String:
	if scene_path.is_empty():
		return ""
	var next_puzzle: Puzzle = load(scene_path).instantiate()
	if next_puzzle == null:
		return ""
	return next_puzzle.get_puzzle_date()
