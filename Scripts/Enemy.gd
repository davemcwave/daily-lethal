extends Node

var health = 10

func _ready():
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	
func hurt(hurt_amount: int) -> void:
	health -= hurt_amount
	
	if health <= 0:
		die()
	
	$EnemyHealthBar.value = health
	$EnemyHealthBar/HealthText.set_text("[center][b]%d/%d[/b][/center]" % [health, $EnemyHealthBar.max_value])
		
func die() -> void:
	print("Dead.")
