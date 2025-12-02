extends Node2D
class_name CardEffect

signal applied
signal player_input_finished

@export var effect_name = ""
@export var effect_description = ""
@export var effect_short_description = ""
@export var requires_player_input: bool = false
@export var effect_color: Color
@export var wait_for_effect_applied: bool = false
@export var effect_panel: PackedScene
@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var audio_handler = get_node("/root/AudioHandler")

func set_effect_name(new_effect_name: String) -> void:
	effect_name = new_effect_name

func get_wait_for_effect_applied() -> bool:
	return wait_for_effect_applied

func get_card_effect_panel() -> PackedScene:
	return effect_panel
	
func get_effect_short_description() -> String:
	return effect_short_description
	
func does_require_player_input() -> bool:
	return requires_player_input
	
func get_effect_name() -> String:
	return effect_name
	
func get_effect_color() -> Color:
	return effect_color
	
func set_effect_description(new_effect_description: String) -> void:
	effect_description = new_effect_description
	
func get_effect_description() -> String:
	return effect_description
	
# TO BE OVERWRITTEN
func apply() -> bool:
	emit_signal("applied")
	return true
