extends Panel

func _on_button_pressed():
	
	OS.shell_open("https://playlethal.beehiiv.com/subscribe")

func _ready():

	swipe_across()
		
func swipe_across() -> void:
	var tween = get_tree().create_tween()
	var original_global_position = global_position
	global_position.x = global_position.x-size.x
	tween.tween_property(self, "global_position:x", original_global_position.x, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
