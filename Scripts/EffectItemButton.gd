extends Button
class_name EffectItemButton

@onready var checkbox: CheckBox = $HBoxContainer/CheckBox

func set_effect_name(new_effect_name: String) -> void:
	$HBoxContainer/Label.set_text("[b]%s[/b]" % new_effect_name)

func _on_pressed():
	checkbox.set_pressed(not checkbox.is_pressed())
