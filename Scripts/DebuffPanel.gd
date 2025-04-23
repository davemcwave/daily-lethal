extends Panel
class_name DebuffPanel

var debuff: Debuff

func blink() -> void:
	var original_color: Color = get_theme_stylebox("panel").bg_color
	get_theme_stylebox("panel").bg_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	get_theme_stylebox("panel").bg_color = original_color
	
	
func set_debuff(new_debuff: Debuff) -> void:
	debuff = new_debuff
	
	debuff.set_debuff_panel(self)
	
func get_debuff() -> Debuff:
	return debuff
	
func set_text(new_text: String) -> void:
	$DebuffText.set_text("[center][b]%s[/b][/center]" % new_text)
