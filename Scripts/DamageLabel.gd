extends RichTextLabel
	
func set_damage(amount: int) -> void:
	set_text("[center][b]-%d[/b][/center]" % amount)
	
func float_up(height_diff: float = 75) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", Vector2(global_position.x + randf_range(-15, 15), global_position.y-height_diff), 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
