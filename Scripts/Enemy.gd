extends Node
class_name Enemy

signal just_hurt(amount: int)

@export var enemy_name: String = ""
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var background = get_node("/root/Background")
@onready var initial_icon_position: Vector2 = $EnemyIcon.position
@export var health = 10
var dead: bool = false
var debuff_activate_queue: Array = []

func _ready():
	background.set_enemy_name(enemy_name)
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	update_health_bar()

func add_to_debuff_activate_queue(debuff: Debuff) -> void:
	debuff_activate_queue.append(debuff_activate_queue)
	
func add_debuff(new_debuff: Debuff) -> void:
	add_child(new_debuff)
	new_debuff.set_target(self)
	$DebuffContainer.add_debuff(new_debuff)
	
func blink_white() -> void:
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 1.0)
	await get_tree().create_timer(0.1).timeout
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 0.0)
	
func get_debuffs() -> Array:
	return $DebuffContainer.get_debuffs()

func activate_on_hurt_debuffs() -> void:
	for debuff: Debuff in get_debuffs():
		if debuff.is_activated_on_hurt():
			await get_tree().create_timer(0.25).timeout
			debuff.activate()
			
func hurt(hurt_amount: int, hurt_from_card: bool = true) -> void:
	health -= hurt_amount
	
	if hurt_from_card:
		activate_on_hurt_debuffs()
		
	shake_briefly()
	blink_white()
	
	if health <= 0:
		die()
	
	update_health_bar()
	scene.check_game_over()
	
func update_health_bar() -> void:
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
