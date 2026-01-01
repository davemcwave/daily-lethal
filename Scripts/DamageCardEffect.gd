extends CardEffect
class_name DamageCardEffect

@export var damage_amount: int = 1
@export var target: Node = null
@export_enum("Player", "Enemy") var target_name: String = "Enemy"
@export var increase_damage_multiplier: int = 1
@export var increase_damage_effect: bool = true
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

func deal_damage(damage_amount: int, context: Dictionary = {}) ->  void:
	if damage_amount > 0:
		var on_deal_damage_buffs: Array = await buffs_container.activate_buffs(Buff.ActivationType.OnDealDamage, context)
		damage_amount = context['current_damage_amount']
	target.hurt(damage_amount)

func get_context() -> Dictionary:
	return context

func apply() -> bool:
	context = {'current_damage_amount': damage_amount, 'deal_damage': true}
	
	var on_attack_buffs: Array = await buffs_container.activate_buffs(Buff.ActivationType.OnAttack, context)
	
	if context['deal_damage']:
		deal_damage(context['current_damage_amount'], context)
	
	var on_hit_buff: Array = await buffs_container.activate_buffs(Buff.ActivationType.OnHit)
	
	return super.apply()
