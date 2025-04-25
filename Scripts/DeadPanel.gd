extends Panel

func appear() -> void:
	modulate.a = 0.0
	show()
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
