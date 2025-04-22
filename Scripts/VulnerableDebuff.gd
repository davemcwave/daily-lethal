extends Debuff

func apply() -> void:
	target.connect("just_hurt", _on_target_just_hurt.bind(target))

func _on_target_just_hurt(hurt_amount: int, target: Enemy) -> void:
	await get_tree().create_timer(0.25).timeout
	target.hurt(1, false)
