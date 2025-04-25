extends TextureRect

@export var health: int = 5
@onready var original_color: Color = self_modulate
var dead: bool = false

func _ready():
	update_text()

func create_damage_label(hurt_amount: int) -> void:
	var damage_label: RichTextLabel = load("res://Scenes/DamageLabel.scn").instantiate()
	damage_label.set_damage(hurt_amount)
	add_child(damage_label)
	damage_label.global_position = global_position
	damage_label.float_up(25.0)

func blink() -> void:
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = original_color
	
func set_health(new_health: int) -> void:
	health = new_health
	update_text()
	
func hurt(amount: int) -> void:
	health -= amount
	
	create_damage_label(amount)
	
	if health <= 0:
		dead = true
		
	update_text()
		
func is_dead() -> bool:
	return dead
	
func update_text() -> void:
	$HealthAmountText.set_text("[center][b]%d[/b][/center]" % health)
