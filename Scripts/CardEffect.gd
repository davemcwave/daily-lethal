extends Node2D
class_name CardEffect

signal applied
signal player_input_finished

@export var effect_name = ""
@export var effect_description = ""
@export var requires_player_input: bool = false

func set_effect_name(new_effect_name: String) -> void:
	effect_name = new_effect_name

func does_require_player_input() -> bool:
	return requires_player_input
	
func get_effect_name() -> String:
	return effect_name
	
func set_effect_description(new_effect_description: String) -> void:
	effect_description = new_effect_description
	
func get_effect_description() -> String:
	return effect_description
	
# TO BE OVERWRITTEN
func apply() -> void:
	emit_signal("applied")
