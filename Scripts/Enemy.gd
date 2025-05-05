extends Node
class_name Enemy

signal just_hurt(amount: int)

@export var enemy_name: String = ""
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var background = get_node("/root/Background")
@onready var initial_icon_position: Vector2 = $EnemyIcon.position
@export var health = 10
var dead: bool = false
var animating: bool = false
var debuff_activate_queue: Array = []
@onready var blink_shader: Shader = load("res://Scripts/Shaders/WhiteBlink.gdshader")
@onready var wobble_shader: Shader = load("res://Scripts/Shaders/Wobble.gdshader")

func _ready():
	set_enemy_name(enemy_name)
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	update_health_bar()
	
	background.set_enemy_texture($EnemyIcon.get_texture())
	$EnemyIcon.material.shader = wobble_shader
	
func set_enemy_name(new_enemy_name: String) -> void:
	enemy_name = new_enemy_name
	background.set_enemy_name(new_enemy_name)
	$EnemyNamePanel/EnemyName.set_text("[center][b]%s[/b][/center]" % enemy_name)
	
func set_health(new_health: int) -> void:
	health = new_health
	
func set_enemy_icon_texture(new_texture: Texture2D) -> void:
	$EnemyIcon.set_texture(new_texture)
	
func add_to_debuff_activate_queue(debuff: Debuff) -> void:
	debuff_activate_queue.append(debuff_activate_queue)
	
func add_debuff(new_debuff: Debuff) -> void:
	add_child(new_debuff)
	new_debuff.set_target(self)
	$DebuffContainer.add_debuff(new_debuff)
	
func blink_white() -> void:
	$EnemyIcon.material.shader = blink_shader
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 1.0)
	
	await get_tree().create_timer(0.1).timeout
	$EnemyIcon.get_material().set_shader_parameter("blink_strength", 0.0)
	$EnemyIcon.material.shader = wobble_shader

func get_debuffs() -> Array:
	return $DebuffContainer.get_debuffs()

func is_animating() -> bool:
	return animating

func get_buffs() -> Array[Buff]:
	var buffs: Array[Buff] = []
	for buff_panel: BuffPanel in $EnemyBuffsContainer.get_children():
		buffs.append(buff_panel.get_buff())
	return buffs
	
func activate_on_hurt_buffs() -> void:
	animating = true
	for buff: Buff in get_buffs():
		if buff.is_activated_on_target_hurt():
			await get_tree().create_timer(0.25).timeout
			buff.activate()
	animating = false
	
func activate_on_hurt_debuffs() -> void:
	animating = true
	for debuff: Debuff in get_debuffs():
		if debuff.is_activated_on_hurt():
			await get_tree().create_timer(0.25).timeout
			debuff.activate()
	animating = false
			
func create_damage_label(hurt_amount: int) -> void:
	var damage_label: RichTextLabel = load("res://Scenes/DamageLabel.scn").instantiate()
	damage_label.set_damage(hurt_amount)
	add_child(damage_label)
	damage_label.global_position = $DamageLabelSpawn.global_position
	damage_label.float_up()
	
	
func hurt(hurt_amount: int, hurt_from_card: bool = true) -> void:
	health -= hurt_amount
	
	create_damage_label(hurt_amount)
	
	if hurt_from_card:
		activate_on_hurt_buffs()
		activate_on_hurt_debuffs()
		
	shake_briefly()
	blink_white()
	
	if health <= 0:
		die()
	
	update_health_bar()
	
	await get_tree().create_timer(0.5).timeout
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
