extends Node2D
class_name Buff

signal activated


@export var buff_name: String = "Buff"
@export var buff_description: String = "Buffs the player"

enum ActivationType {OnCardPlay, OnAttack, OnHit, OnHurt, ManuallyHandled, OnCardDiscarded, OnDealDamage}
@export var activation_type: ActivationType
@export var extra_activation_types: Array[ActivationType] = []

@export var uses_amount: int = 1
@export var unlimited_uses: bool = false

@export var wait_for_activated_signal: bool = true

var buff_panel: BuffPanel = null
@export var target: Node = null

@export var color: Color = Color.WHITE

# True if this type of buff can only be played once per turn
@export var activated_once_per_turn: bool = false
@export var single_turn_repeat: bool = false

enum OnPlayActivationCategory {OnPlayAttackCard}
@export var on_play_activation_category = OnPlayActivationCategory.OnPlayAttackCard

@export var freed_manually: bool = false
@export var deal_damage: bool = true
@export var merge_buff_panels: bool = false

var activation_ids: Array[int] = []

func can_deal_damage() -> bool:
	return deal_damage

func can_single_turn_repeat() -> bool:
	return single_turn_repeat

func set_single_turn_repeat(new_single_turn_repeat: bool) -> void:
	single_turn_repeat = new_single_turn_repeat
	
func set_deal_damage(new_deal_damage: bool) -> void:
	deal_damage = new_deal_damage

func is_freed_manually() -> bool:
	return freed_manually
	
func set_target(new_target: Node) -> void:
	target = new_target

func get_on_play_activation_category() -> OnPlayActivationCategory:
	return on_play_activation_category
	
func set_color(new_color: Color) -> void:
	#print("%s set to %s" % [name, str(new_color)])
	color = new_color
	
func get_color() -> Color:
	return color

func can_merge_with(other_buff: Buff) -> bool:
	return false

func merge_with(other_buff: Buff) -> void:
	pass
	
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

func get_activation_type() -> ActivationType:
	return activation_type
	
func get_activation_types() -> Array[int]:
	var activation_types: Array[int] = [activation_type]
	for extra_activation_type in extra_activation_types:
		if not activation_types.has(extra_activation_type):
			activation_types.append(extra_activation_type)
	return activation_types

func matches_activation_type(target_activation_type: ActivationType) -> bool:
	return get_activation_types().has(target_activation_type)
	
func is_activated_on_target_hit() -> bool:
	return matches_activation_type(ActivationType.OnHit)
	
func is_activated_on_card_play() -> bool:
	return matches_activation_type(ActivationType.OnCardPlay)

func is_activated_on_target_hurt() -> bool:
	return matches_activation_type(ActivationType.OnHurt)
	
func is_activated_manually() -> bool:
	return matches_activation_type(ActivationType.ManuallyHandled)
	
func is_activated_on_card_discarded() -> bool:
	return matches_activation_type(ActivationType.OnCardDiscarded)

func can_be_activated_more_than_once_per_turn() -> bool:
	return not activated_once_per_turn

func can_be_activated_only_once_per_turn() -> bool:
	return activated_once_per_turn


func has_seen_activation_id(activation_id: int) -> bool:
	return activation_id in activation_ids

# TO BE OVERWRITTEN - context includes 'activation_type' to describe the triggering event
func activate(context: Dictionary = {}) -> bool:
	if not is_unlimited_uses():
		uses_amount -= 1
		
	if context.has('activation_id'):
		activation_ids.append(context['activation_id'])
		
	
	buff_panel.blink()
	emit_signal("activated")
	return true

func is_unlimited_uses() -> bool:
	return unlimited_uses
	
func exceeded_uses() -> bool:
	#print("Exceeded uses | not is_unlimited_uses(): %s,  uses_amount <= 0: %s, uses_amount: %s" % [str(not is_unlimited_uses()),  str(uses_amount <= 0), str(uses_amount)])
	return not is_unlimited_uses() and uses_amount <= 0
