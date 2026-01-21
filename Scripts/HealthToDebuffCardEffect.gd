extends CardEffect

@export_file("*.scn") var debuff_scene
@export var target: Node = null
@onready var health: Health = get_tree().get_root().get_node("Scene/Health")

func _ready() -> void:
	target = get_tree().get_root().get_node("Scene/Enemy")
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> bool:
	var health_reduced: int = health.get_health() - 1
	health.hurt(health_reduced)
	
	for i in range(health_reduced):
		var debuff: Debuff = load(debuff_scene).instantiate()
		target.add_debuff(debuff)
		
	return super.apply()
