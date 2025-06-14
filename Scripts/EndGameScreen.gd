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
	$VBoxContainer/BestAttemptText.set_text("[center][b]WITH [color=gold]%d[/color] CARDS PLAYED \nON LAST ATTEMPT[/b][/center]" % background.best_card_count)
	$EnemyIcon.set_texture(background.get_enemy_texture())

func _on_play_again_button_pressed():
	background.clear()
	get_tree().change_scene_to_file("res://Scenes/Scene0.scn")

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
	background.clear()
	
	if background.get_is_current_puzzle():
		OS.shell_open("https://playlethal.beehiiv.com/subscribe")
	else:
		var next_puzzle: Puzzle = load(background.get_next_puzzle_scene()).instantiate()
		var next_puzzle_date: String = next_puzzle.get_puzzle_date()
		#OS.shell_open("https://playlethal.fun/%s" % next_puzzle_date)
		open_window_in_same_tab("https://playlethal.fun/%s" % next_puzzle_date)
		
func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
