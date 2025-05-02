extends Node2D
class_name Buff

signal activated


@export var buff_name: String = "Buff"
@export var buff_description: String = "Buffs the player"

enum ActivationType {OnCardPlay, OnAttack, OnHit, OnHurt, ManuallyHandled}
@export var activation_type: ActivationType

@export var uses_amount: int = 1
@export var unlimited_uses: bool = false

var buff_panel: BuffPanel = null
@export var target: Node = null

@export var color: Color = Color.WHITE

func set_target(new_target: Node) -> void:
	target = new_target

func set_color(new_color: Color) -> void:
	#print("%s set to %s" % [name, str(new_color)])
	color = new_color
	
func get_color() -> Color:
	return color
	
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
	
func is_activated_on_target_hit() -> bool:
	return activation_type == ActivationType.OnHit
	
func is_activated_on_card_play() -> bool:
	return activation_type == ActivationType.OnCardPlay

func is_activated_on_target_hurt() -> bool:
	return activation_type == ActivationType.OnHurt
	
func is_activated_manually() -> bool:
	return activation_type == ActivationType.ManuallyHandled
	
# TO BE OVERWRITTEN
func activate() -> void:
	if not is_unlimited_uses():
		uses_amount -= 1
	
	buff_panel.blink()
	emit_signal("activated")

func is_unlimited_uses() -> bool:
	return unlimited_uses
	
func exceeded_uses() -> bool:
	#print("Exceeded uses | not is_unlimited_uses(): %s,  uses_amount <= 0: %s, uses_amount: %s" % [str(not is_unlimited_uses()),  str(uses_amount <= 0), str(uses_amount)])
	return not is_unlimited_uses() and uses_amount <= 0
