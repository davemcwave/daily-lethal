extends Node2D
class_name Buff

signal activated

const UNLIMITED_USES = -42
@export var buff_name: String = "Buff"
@export var buff_description: String = "Buffs the player"

enum ActivationType {OnCardPlay, OnAttack, OnHurt}
@export var activation_type: ActivationType

@export var uses_amount: int = 1

var buff_panel: BuffPanel = null

func set_buff_panel(new_buff_panel: BuffPanel) -> void:
	buff_panel = new_buff_panel
	
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

func is_activated_on_target_hurt() -> bool:
	return activation_type == ActivationType.OnHurt
# TO BE OVERWRITTEN
func activate() -> void:
	if is_unlimited_uses():
		uses_amount -= 1
	buff_panel.blink()

func is_unlimited_uses() -> bool:
	return uses_amount == UNLIMITED_USES
	
func exceeded_uses() -> bool:
	return not is_unlimited_uses() and uses_amount <= 0
