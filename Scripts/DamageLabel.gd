extends RichTextLabel
	
func set_damage(amount: int) -> void:
	if amount == 0:
		set_text("[center][b]BLOCKED![/b][/center]")
	else:
		set_text("[center][b]-%d[/b][/center]" % amount)
	
func float_up(height_diff: float = 75) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", Vector2(global_position.x + randf_range(-10, 10), global_position.y-randf_range(height_diff/1.25, height_diff)), 0.85).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
