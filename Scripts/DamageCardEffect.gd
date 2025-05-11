extends CardEffect
class_name DamageCardEffect

@export var damage_amount: int = 1
@export var target: Node = null

func _ready() -> void:
	target = get_tree().get_root().get_node("Scene/Enemy")

func set_damage_amount(new_damage_amount: int) -> void:
	damage_amount = new_damage_amount
	
func get_damage_amount() -> int:
	return damage_amount
	
func increase_damage_amount(damage_increase_amount: int) -> void:
	damage_amount += damage_increase_amount
	
	var card: Card = get_parent()
	card.update_description_panel()
	
	#if not card.is_bouncing():
	await get_tree().create_timer(0.1).timeout
	card.inflate(true)
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> void:
	target.hurt(damage_amount)
