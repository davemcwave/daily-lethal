extends CardEffect

@export var health_amount: int = 1
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func set_health_amount(new_health_amount: int) -> void:
	health_amount = new_health_amount
	
func get_health_amount() -> int:
	return health_amount
	
func apply() -> void:
	health.set_health(health_amount)
