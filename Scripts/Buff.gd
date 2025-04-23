extends Node2D
class_name Buff

signal activated

@export var buff_name: String = "Buff"
@export var buff_description: String = "Buffs the player"

enum ActivationType {OnCardPlay, OnAttack}
@export var activation_type: ActivationType

@export var uses_amount: int = 1

	
func set_buff_name(new_buff_name: String) -> void:
	buff_name = new_buff_name
	
func set_buff_description(new_buff_description: String) -> void:
	buff_description = new_buff_description
	
func get_buff_name() -> String:
	return buff_name
	
func get_buff_description() -> String:
	return buff_description
	
func is_activated_on_card_play() -> bool:
	return activation_type == ActivationType.OnCardPlay

# TO BE OVERWRITTEN
func activate() -> void:
	uses_amount -= 1
	
func exceeded_uses() -> bool:
	return uses_amount <= 0
