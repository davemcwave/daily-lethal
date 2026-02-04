extends Control

var share_text_template = "💀 I defeated the {enemy_name} in {attempt_count} attempt{attempt_plural}!\n🃏 My solution: {best_card_count} cards\nPlay today’s puzzle 👉 https://playlethal.fun" # https://playlethal.fun"
var share_text = ""
@onready var background = get_node("/root/Background")
func _ready():
	var attempt_plural: String = '' if background.attempts <= 1 else 's'
	share_text = share_text_template.format(
		{
			'enemy_name': background.enemy_name,
			'attempt_plural': attempt_plural,
			'attempt_count': background.attempts,
			'best_card_count': background.best_card_count,
		}
	)

	$VBoxContainer/AttemptText.set_text("[center][b]IN [color=green]%d[/color] ATTEMPT%s[/b][/center]" % [background.attempts, attempt_plural.to_upper()])
	$VBoxContainer/BestAttemptText.set_text("[center][b]WITH [color=gold]%d[/color] CARDS PLAYED[/b][/center]" % background.best_card_count)
	$EnemyIcon.set_texture(background.get_enemy_texture())

	background.mark_puzzle_completed(background.get_puzzle_date())
	background.save_played_cards_solution()

	if background.is_from_story_view():
		background.mark_story_puzzle_completed(background.get_puzzle_scene())

func _on_play_again_button_pressed():
	background.clear()
	
	if is_web_platform():
		if JavaScriptBridge.eval("localStorage.getItem('device_type')", true) == "desktop":
			get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Scene0.scn")
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

	if next_puzzle_scene == null:
		OS.shell_open("https://playlethal.beehiiv.com/subscribe")
	else:
		if is_web_platform():
			var next_puzzle: Puzzle = load(next_puzzle_scene).instantiate()
			if next_puzzle == null:
				return
			var next_puzzle_date: String = next_puzzle.get_puzzle_date()
			var base_url = JavaScriptBridge.eval("window.location.origin", true)
			var device_type = JavaScriptBridge.eval("localStorage.getItem('device_type')", true)
			var desktop = "/desktop" if device_type == "desktop" else ""
			var next_url = "%s%s/%s" % [base_url, desktop, next_puzzle_date]
			open_window_in_same_tab(next_url)
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
