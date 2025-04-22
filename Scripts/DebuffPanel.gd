extends Panel

func set_text(new_text: String) -> void:
	$DebuffText.set_text("[center][b]%s[/b][/center]" % new_text)
