extends Node
class_name Enemy

@export var enemy_name: String = ""
@onready var background = get_node("/root/Background")
@onready var initial_icon_position: Vector2 = $EnemyIcon.position
var health = 10
var dead: bool = false

func _ready():
	background.set_enemy_name(enemy_name)
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health

func blink_white() -> void:
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 1.0)
	await get_tree().create_timer(0.1).timeout
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 0.0)
	
func hurt(hurt_amount: int) -> void:
	health -= hurt_amount
	shake_briefly()
	blink_white()
	
	if health <= 0:
		die()
	
	$EnemyHealthBar.value = health
	$EnemyHealthBar/HealthText.set_text("[center][b]%d/%d[/b][/center]" % [health, $EnemyHealthBar.max_value])

func shake_briefly():
	$EnemyIcon.position = initial_icon_position
	var tween = get_tree().create_tween()
	var original_pos = $EnemyIcon.position

	for i in range(3):
		var offset = Vector2(randi() % 10 - 2, randi() % 6 - 1)
		tween.tween_property($EnemyIcon, "position", original_pos + offset, 0.02)
	tween.tween_property($EnemyIcon, "position", original_pos, 0.02)

#func _input(event):
	#if event.is_action_pressed("ui_accept"):
		#shake_briefly()
		
func is_dead() -> bool:
	return dead
	
func die() -> void:
	$EnemyIcon.hide()
	$DefeatIcon.show()
	dead = true
