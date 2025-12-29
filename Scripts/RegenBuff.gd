extends Buff

@export var heal_amount: int = 1
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func activate(context: Dictionary = {}) -> bool:
	health.add_health(heal_amount)
	return super.activate()
