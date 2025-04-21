extends TextureRect

@export var health: int = 5
var dead: bool = false

func _ready():
	update_text()

func set_health(new_health: int) -> void:
	health = new_health
	update_text()
	
func hurt(amount: int) -> void:
	health -= amount
	
	if health <= 0:
		dead = true
		
	update_text()
		
func is_dead() -> bool:
	return dead
	
func update_text() -> void:
	$HealthAmountText.set_text("[center][b]%d[/b][/center]" % health)
