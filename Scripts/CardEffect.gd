extends Node2D
class_name CardEffect

var effect_name = ""
var effect_description = ""

func set_effect_name(new_effect_name: String) -> void:
	effect_name = new_effect_name
	
func get_effect_name() -> String:
	return effect_name
	
func set_effect_description(new_effect_description: String) -> void:
	effect_description = new_effect_description
	
func get_effect_description() -> String:
	return effect_description
	
# TO BE OVERWRITTEN
func apply() -> void:
	pass
