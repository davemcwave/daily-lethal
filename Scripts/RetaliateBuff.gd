extends Buff

@onready var scene = get_tree().get_root().get_node("Scene")
@onready var enemy: Enemy = scene.get_node("Enemy")
func activate() -> void:
	enemy.hurt(1)
	
