extends Node
class_name Enemy

signal just_hurt(amount: int)

@export var enemy_name: String = ""
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var background = get_node("/root/Background")
@onready var initial_icon_position: Vector2 = $EnemyIcon.position
@export var health = 10
@export var enemy_name_font_size = -1
var dead: bool = false
var animating: bool = false
var debuff_activate_queue: Array = []
@onready var blink_shader: Shader = load("res://Scripts/Shaders/WhiteBlink.gdshader")
@onready var wobble_shader: Shader = load("res://Scripts/Shaders/Wobble.gdshader")
@onready var audio_handler = $"/root/AudioHandler"
@onready var dialog_handler = $"/root/DialogHandler"
@onready var custom_camera: CustomCamera = scene.get_node("CustomCamera")
var hurt_lines: Array[String] = []
var hurt_lines_bag: Array[String] = []
var hurt_line_chance: float = 0.0

func _ready():
	set_enemy_name(enemy_name)
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	update_health_bar()
	
	background.set_enemy_texture($EnemyIcon.get_texture())
	$EnemyIcon.material.shader = wobble_shader

func set_hurt_line_chance(new_hurt_line_chance: float) -> void:
	hurt_line_chance = new_hurt_line_chance
	
func get_hurt_line_chance() -> float:
	return hurt_line_chance
	
func set_hurt_lines(new_hurt_lines: Array[String]) -> void:
	hurt_lines = new_hurt_lines
	hurt_lines_bag = hurt_lines.duplicate(true)
	
func get_hurt_lines() -> Array[String]:
	return hurt_lines
	
func set_enemy_name(new_enemy_name: String) -> void:
	enemy_name = new_enemy_name
	background.set_enemy_name(new_enemy_name)
	$EnemyNamePanel/EnemyName.set_text("[center][b]%s[/b][/center]" % enemy_name)
	
	if len(enemy_name) >= 19:
		var current_enemy_name_font_size: int = $EnemyNamePanel/EnemyName.get("theme_override_font_sizes/bold_font_size") if enemy_name_font_size <= 0 else enemy_name_font_size 
		$EnemyNamePanel/EnemyName.set("theme_override_font_sizes/bold_font_size",enemy_name_font_size)
		
func set_health(new_health: int) -> void:
	health = new_health
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	update_health_bar()
	
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

func create_hurt_text(hurt_text_message: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = hurt_text_message
	
	var random_rotation = randf_range(-25, 25)
	
	var y_offset: float = 20
	var word_count = 1
	for word in label.get_parsed_text().split(" "):
		var hurt_text: RichTextLabel = load("res://Scenes/HurtText.scn").instantiate()
		add_child(hurt_text)
		hurt_text.global_position = $EnemyIcon.global_position + $EnemyIcon.size/2
		hurt_text.rotation_degrees += random_rotation
		hurt_text.position.y += (y_offset * word_count)
		hurt_text.set_text(hurt_text_message)
		hurt_text.play_hurt_text(word, hurt_text.position)
		word_count += 1
		await get_tree().create_timer(0.15).timeout

func get_random_hurt_line() -> String:
	if hurt_lines_bag.size() <= 0:
		hurt_lines_bag = hurt_lines.duplicate(true)
		
	hurt_lines_bag.shuffle()
	return hurt_lines_bag.pop_back()
	
func hurt(hurt_amount: int, hurt_from_card: bool = true) -> void:
	health -= hurt_amount
	
	create_damage_label(hurt_amount)
	
	if hurt_from_card and hurt_amount > 0:
		activate_on_hurt_buffs()
		activate_on_hurt_debuffs()
	
	if hurt_amount > 0:
		audio_handler.play_sfx("HurtSFX")
		custom_camera.add_trauma(0.2)
		audio_handler.increase_pitch_scale("HurtSFX", 0.05)
	
	if dialog_handler.is_enabled() and randf() <= hurt_line_chance:
		create_hurt_text(get_random_hurt_line())
		
	shake_briefly()
	blink_white()
	
	if health <= 0:
		die()
	
	update_health_bar()
	
	while background.cards_are_playing():
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
