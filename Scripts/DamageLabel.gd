extends RichTextLabel
	
func set_damage(amount: int) -> void:
	set_text("[center][b]-%d[/b][/center]" % amount)
	
func float_up() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", Vector2(global_position.x + randf_range(-15.0, 15.0), global_position.y-75.0), 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
