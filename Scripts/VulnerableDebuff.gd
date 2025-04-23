extends Debuff
#
#func apply() -> void:
	#target.connect("just_hurt", _on_target_just_hurt.bind(target))

func activate() -> void:
	target.hurt(1, false)
	
