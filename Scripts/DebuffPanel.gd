extends Panel
class_name DebuffPanel

var debuff: Debuff

func set_debuff(new_debuff: Debuff) -> void:
	debuff = new_debuff
	
func get_debuff() -> Debuff:
	return debuff
	
func set_text(new_text: String) -> void:
	$DebuffText.set_text("[center][b]%s[/b][/center]" % new_text)
