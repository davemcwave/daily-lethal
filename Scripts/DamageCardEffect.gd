extends CardEffect
class_name DamageCardEffect

@export var damage_amount: int = 1
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
	return increase_damage_effect
	
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
	target.hurt(damage_amount)

func get_context() -> Dictionary:
	return context

func apply() -> bool:
	var should_apply_damage_buffs: bool = target_name == "Enemy" or increase_damage_effect_for_player
	context = {
		'current_damage_amount': damage_amount,
		'deal_damage': true,
		'target_name': target_name,
	}
	
	if should_apply_damage_buffs:
		await buffs_container.activate_buffs(Buff.ActivationType.OnAttack, context)
	
	if context['deal_damage']:
		await deal_damage(context['current_damage_amount'], context, should_apply_damage_buffs)
	
	await buffs_container.activate_buffs(Buff.ActivationType.OnHit)
	
	return super.apply()
