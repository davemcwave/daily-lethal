extends Panel

const BANNER_WAIT_TIME_SECONDS: float = 3.0
func _ready():
	if not has_seen_intro():
		show()
		swipe_down()
		set_intro_seen()
		await get_tree().create_timer(BANNER_WAIT_TIME_SECONDS).timeout
		swipe_up()
	else:
		hide()
		
func swipe_down() -> void:
	var tween = get_tree().create_tween()
	var original_global_position = global_position
	global_position.y = global_position.y-size.y
	tween.tween_property(self, "global_position:y", original_global_position.y, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func swipe_up() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position:y", global_position.y-size.y, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(queue_free)
	
func has_seen_intro() -> bool:
	var lethal_intro_seen = JavaScriptBridge.eval("localStorage.getItem('lethal_intro_seen') === 'true'", true)
	if lethal_intro_seen == null:
		return false
	return lethal_intro_seen
	
func set_intro_seen():
	JavaScriptBridge.eval("localStorage.setItem('lethal_intro_seen', 'true')", true)
