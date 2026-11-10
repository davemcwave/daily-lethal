extends CardEffect
class_name DamageCardEffect

@export var damage_amount: int = 1
## Permanent "+damage" this effect has received (Rage, Spark's +1 to Sparks).
## Normal cards also add it to damage_amount; count-based cards (Heartbeat,
## Thunderbolt, Shovel, Balance) deal count + damage_bonus. Kept with the card
## (copies included) but not card data: it's gained during play.
@export var damage_bonus: int = 0
@export var target: Node = null
@export_enum("Player", "Enemy") var target_name: String = "Enemy"
@export var increase_damage_multiplier: int = 1
@export var increase_damage_effect: bool = true
@export var increase_damage_effect_for_player: bool = false
@export var modifiable: bool = true
@onready var energy: Energy = scene.get_node('Energy')
var context: Dictionary = {}
	
func is_modifiable() -> bool:
	return modifiable
	
func set_modifiable(new_modifiable: bool) -> void:
	modifiable = new_modifiable

func can_increase_damage_amount() -> bool:
	return increase_damage_effect and (target_name == "Enemy" or increase_damage_effect_for_player)
	
func _ready() -> void:
	if target_name == "Enemy":
		target = get_tree().get_root().get_node("Scene/Enemy")
	else:
		target = get_tree().get_root().get_node("Scene/Health")
		
func get_effect_short_description() -> String:
	return "Deal %d damage" % damage_amount

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount
	
func increase_damage_amount(damage_increase_amount: int) -> void:
	damage_amount += (damage_increase_amount * increase_damage_multiplier)
	damage_bonus += (damage_increase_amount * increase_damage_multiplier)
	
	var card: Card = get_parent()
	card.update_description_panel()
	
	audio_handler.play_sfx("EnhanceOtherCardsSFX")
	audio_handler.increase_pitch_scale("EnhanceOtherCardsSFX", 0.25)
	await get_tree().create_timer(0.1).timeout
	await card.inflate(false if not card.is_discarded() else true)
	
func set_target(new_target) -> void:
	target = new_target

func deal_damage(damage_amount: int, context: Dictionary = {}, apply_buffs: bool = true) ->  void:
	if apply_buffs and damage_amount > 0:			
		await buffs_container.activate_buffs(Buff.ActivationType.OnDealDamage, context)
		damage_amount = context['current_damage_amount']
	await target.hurt(damage_amount)

func get_context() -> Dictionary:
	return context

func apply() -> bool:
	var should_apply_damage_buffs: bool = target_name == "Enemy" or increase_damage_effect_for_player
	context = {
		'current_damage_amount': damage_amount,
		'deal_damage': true,
		'target_name': target_name,
	}
	
	# The attack's damage report starts here: whatever HP the target loses from now
	# until the attack has landed (the hit, or Splinter's pieces).
	var target_health_before: int = target.get_health() if target != null and target.has_method("get_health") else 0

	# Attack order: base -> Add (Sharp) -> Multiply (Critical) -> Split (Splinter)
	# -> Convert (Charge, Flame, Poison) -> Deal damage (each hit lands; the enemy's
	# Vulnerable adds to each one, in Enemy.hurt) -> Reactions (Lifesteal, Retaliate).
	if should_apply_damage_buffs:
		await buffs_container.activate_buffs(Buff.ActivationType.OnAttack, context)

	if context['deal_damage']:
		var hits: Array = context.get('hits', [])
		if hits.is_empty():
			await deal_damage(context['current_damage_amount'], context, should_apply_damage_buffs)
		else:
			# Split by Splinter: the pieces land one after another.
			for hit in hits:
				await target.hurt(hit)
				await get_tree().create_timer(0.07).timeout

	var damage_dealt: int = target_health_before - target.get_health() if target != null and target.has_method("get_health") else 0
	context['damage_dealt'] = maxi(damage_dealt, 0)
	if should_apply_damage_buffs and context['damage_dealt'] > 0:
		await buffs_container.activate_buffs(Buff.ActivationType.React, context)
		if target is Enemy:
			await target.activate_react_buffs(context)  # Retaliate, Corrode

	await buffs_container.activate_buffs(Buff.ActivationType.OnHit)
	
	return super.apply()

## Hover preview: the damage this effect would start from if its card were played
## now, before buffs. Effects with their own rule (HP, energy, discard pile) override
## it. Never changes anything.
func get_preview_damage_amount() -> int:
	return damage_amount

## Energy left once this effect's card is paid for (Free / Discount / Blood
## included), for energy-based damage previews.
func _preview_energy_after_cost() -> int:
	var card := get_parent() as Card
	var cost: int = card.get_energy_cost() if card != null else 0
	if buffs_container.has_free_buff() or buffs_container.has_blood_buff():
		cost = 0
	elif buffs_container.has_discount_buff():
		cost = buffs_container.get_discounted_cost(cost)
	return energy.get_energy_amount() - cost

## True when the damage comes from a count (your HP, energy, discard pile) instead
## of a number in the card's text: the card then adds "(Deals N damage)" with the
## live amount, like Slay the Spire's Body Slam.
func is_count_based() -> bool:
	return false

## The formula's starting steps for this effect: its base, or for count-based
## effects the count plus bonuses ("5 hp + 1 rage"; their base is always 0).
func get_preview_start_steps() -> Array:
	return [{"op": "start", "value": get_preview_damage_amount(), "name": "base"}]

func _count_steps(count: int, count_name: String) -> Array:
	var steps: Array = [{"op": "start", "value": count, "name": count_name}]
	if damage_bonus > 0:
		steps.append({"op": "+", "value": damage_bonus, "name": "rage"})
	return steps
