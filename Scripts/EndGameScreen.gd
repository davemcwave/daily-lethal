extends Control

var share_text_template = "💀 I defeated the {enemy_name} in {attempt_count} attempt{attempt_plural}!\n🃏 My solution: {best_card_count} cards\nPlay today’s puzzle 👉 https://playlethal.fun"
var share_text = ""
@onready var background = get_node("/root/Background")

func _ready():
	var attempt_plural: String = '' if background.attempts <= 1 else 's'
	share_text = share_text_template.format(
		{
			'enemy_name': background.enemy_name, 
			'attempt_plural': attempt_plural,
			'attempt_count': background.attempts, 
			'best_card_count': background.best_card_count
		}
	)
	
	$VBoxContainer/AttemptText.set_text("[center][b]IN [color=green]%d[/color] ATTEMPT%s[/b][/center]" % [background.attempts, attempt_plural.to_upper()])
	$VBoxContainer/BestAttemptText.set_text("[center][b]WITH [color=gold]%d[/color] CARDS PLAYED \nON LAST ATTEMPT[/b][/center]" % background.best_card_count)
	

func _on_play_again_button_pressed():
	background.clear()
	get_tree().change_scene_to_file("res://Scenes/Scene0.scn")

func _on_share_button_pressed():
	DisplayServer.clipboard_set(share_text)
	$ShareButton.set_text("COPIED!")
	$ShareButton.set_disabled(true)
	await get_tree().create_timer(1.5).timeout
	$ShareButton.set_disabled(false)
	$ShareButton.set_text("SHARE")

func _on_get_tomorrow_button_pressed():
	OS.shell_open("https://playlethal.beehiiv.com/subscribe")
