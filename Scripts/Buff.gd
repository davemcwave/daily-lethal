extends Node2D
class_name Buff

signal activated


@export var buff_name: String = "Buff"
@export var buff_description: String = "Buffs the player"

## React: once an attack has landed; context["damage_dealt"] is the HP the
## target lost from it, splash (Vulnerable) and every Splinter piece included.
enum ActivationType {OnCardPlay, OnAttack, OnHit, OnHurt, ManuallyHandled, OnCardDiscarded, OnDealDamage, React}
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
@export var on_play_activation_category: OnPlayActivationCategory = OnPlayActivationCategory.OnPlayAttackCard

@export var freed_manually: bool = false
@export var deal_damage: bool = true
@export var merge_buff_panels: bool = false
# Lower priority fires first within the same activation type.
# 0 = modifier (e.g. Critical), 1 = replacement (e.g. Charge, Poison)
@export var priority: int = 0

var activation_ids: Array[int] = []
var source_card_ref: WeakRef = null

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

func get_target() -> Node:
	return target

func set_source_card(card: Card) -> void:
	source_card_ref = weakref(card) if card != null else null

func get_source_card() -> Card:
	return source_card_ref.get_ref() if source_card_ref != null else null
	
func get_other_target() -> Node:
	if target is Health:
		return get_tree().get_root().get_node('Scene/Enemy')
	else:
		return get_tree().get_root().get_node('Scene/Health')

func get_on_play_activation_category() -> OnPlayActivationCategory:
	return on_play_activation_category
	
func set_color(new_color: Color) -> void:
	#print("%s set to %s" % [name, str(new_color)])
	color = new_color
	
func get_color() -> Color:
	return color

## Whether a new buff joins this one's box for real (its numbers add up). Off by
## default: separate buffs of a kind act separately (two Returns can each act),
## and released puzzles depend on that. Sharp and Splinter merge. Same-kind boxes
## are still shown as one by BuffsContainer (display only).
func can_merge_with(other_buff: Buff) -> bool:
	return false

func merge_with(other_buff: Buff) -> void:
	pass

## The box's label: the buff's name, plus its uses when it has more than one
## ("Critical 2"); buffs whose name already shows a count (Sharp 3) keep it.
func get_display_name() -> String:
	var shown := get_buff_name()
	if shown == buff_name and not is_unlimited_uses() and uses_amount > 1:
		shown += " %d" % uses_amount
	return shown
	
func set_buff_panel(new_buff_panel: BuffPanel) -> void:
	buff_panel = new_buff_panel
	
func set_buff_name(new_buff_name: String) -> void:
	buff_name = new_buff_name
	
func set_buff_description(new_buff_description: String) -> void:
	buff_description = new_buff_description
	
func get_buff_name() -> String:
	return buff_name
	
## The text with X filled in by this buff's number ("The next 2 times you deal
## damage..."), like Slay the Spire's tooltips.
func get_buff_description() -> String:
	return fill_x(buff_description, get_description_number(), self)

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
		if is_instance_valid(buff_panel) and uses_amount > 0:
			buff_panel.update_text()  # "Critical 2" -> "Critical 1"

	if context.has('activation_id'):
		activation_ids.append(context['activation_id'])
		
	
	buff_panel.blink()
	emit_signal("activated")
	return true

func is_unlimited_uses() -> bool:
	return unlimited_uses

func should_show_unlimited_panel() -> bool:
	return is_unlimited_uses()
	
## Out of uses (Splinter counts its own stacks). An attack status that runs out
## stays until its attack card's effects are done (BuffsContainer), so every hit
## of that card gets it.
func is_used_up() -> bool:
	return exceeded_uses()

func exceeded_uses() -> bool:
	#print("Exceeded uses | not is_unlimited_uses(): %s,  uses_amount <= 0: %s, uses_amount: %s" % [str(not is_unlimited_uses()),  str(uses_amount <= 0), str(uses_amount)])
	return not is_unlimited_uses() and uses_amount <= 0

## Hover preview: what this buff would do to an attack, without changing anything.
## Works on the same context as activate() ("current_damage_amount", "deal_damage",
## plus "hits" for split attacks), in the same tier order. Returns the step for
## the formula, or {} if it wouldn't act:
##   {"op": "+", "value": 1, "name": "sharp"}	  add
##   {"op": "x", "value": 2, "name": "critical"}   multiply
##   {"op": "to", "text": "+8 energy", "name": "charge"}   convert / split
func preview_attack(context: Dictionary) -> Dictionary:
	return {}

## Hover preview for React buffs: context["damage_dealt"] is the attack's
## total. Returns {"op": "after", "text": "heal 8", "name": "lifesteal"} or {}.
func preview_react(context: Dictionary) -> Dictionary:
	return {}

## Whether this buff would act if `card` were played now, for the "will be used"
## highlight while a card is held over the play area. Buffs that react to playing
## a card (Regen, Doom, Sharp's countdown) or to the next card played (Copy,
## Return, Trash) act on any card; attack-step buffs (Sharp's bonus, Critical,
## Charge, ...) come from the damage preview instead.
func would_act_on_card(card: Card) -> bool:
	return matches_activation_type(ActivationType.OnCardPlay) or matches_activation_type(ActivationType.OnCardDiscarded)

## What X means in this buff's text: its uses (Critical 2 = next 2 attacks), unless
## the buff counts something else (Sharp, Doom override this).
func get_description_number() -> int:
	return uses_amount

## Fills in a status text:
##   X				  -> the number ("Damage increased by X" -> "...by 3")
##   [singular|plural]  -> picked by the number ("Next [card|X cards]")
##   {setting}		  -> the status's own setting ("by {discount_amount}")
static func fill_x(text: String, number: int, source: Object = null) -> String:
	var filled := text
	if source != null:
		for found in RegEx.create_from_string("\\{(\\w+)\\}").search_all(text):
			var value = source.get(found.get_string(1))
			if value != null:
				filled = filled.replace(found.get_string(0), str(value))
	for found in RegEx.create_from_string("\\[([^|\\]]*)\\|([^\\]]*)\\]").search_all(filled):
		filled = filled.replace(found.get_string(0), found.get_string(1) if number == 1 else found.get_string(2))
	return RegEx.create_from_string("\\bX\\b").sub(filled, str(number), true)
