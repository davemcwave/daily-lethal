extends DamageCardEffect
class_name HealthBasedDamageCardEffect

@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func apply() -> void:
	var hp: int = health.get_health()
	set_damage_amount(hp)
	super.apply()
	
func get_damage_amount() -> int:
	return health.get_health()
	
