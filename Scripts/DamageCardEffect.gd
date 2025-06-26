extends CardEffect
class_name DamageCardEffect

@export var damage_amount: int = 1
@export var target: Node = null
@export_enum("Player", "Enemy") var target_name: String = "Enemy"
@export var increase_damage_multiplier: int = 1
@export var increase_damage_effect: bool = true

func can_increase_damage_amount() -> bool:
	return increase_damage_effect
	
func _ready() -> void:
	if target_name == "Enemy":
		target = get_tree().get_root().get_node("Scene/Enemy")
	else:
		target = get_tree().get_root().get_node("Scene/Health")

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount
	
func increase_damage_amount(damage_increase_amount: int) -> void:
	damage_amount += (damage_increase_amount * increase_damage_multiplier)
	
	var card: Card = get_parent()
	card.update_description_panel()
	
	#if not card.is_bouncing():
	await get_tree().create_timer(0.1).timeout
	card.inflate(false)
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> void:
	buffs_container.activate_on_hit_buffs()
	
	target.hurt(damage_amount)
