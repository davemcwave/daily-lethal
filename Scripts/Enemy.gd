extends Node
class_name Enemy

signal just_hurt(amount: int)
signal died

@export var enemy_name: String = ""
@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var background = get_node("/root/Background")
@onready var initial_icon_position: Vector2 = $EnemyIcon.position
@export var health = 10
@export var enemy_name_font_size = -1

var max_health = 0
var difficulty: String = "Normal"
var dead: bool = false
var animating: bool = false
var debuff_activate_queue: Array = []

@onready var blink_shader: Shader = load("res://Scripts/Shaders/WhiteBlink.gdshader")
@onready var wobble_shader: Shader = load("res://Scripts/Shaders/Wobble.gdshader")
@onready var shake_shader: Shader = load("res://Scripts/Shaders/Shake.gdshader")
@onready var wobble_material: Material = load("res://Resources/EnemyWobbleMaterial.res")
@onready var shake_material: Material = load("res://Resources/ShakeMaterial.res")
@onready var audio_handler = $"/root/AudioHandler"
@onready var dialog_handler = $"/root/DialogHandler"
@onready var nightmare_icon: TextureRect = $NightmareIcon
@onready var custom_camera: CustomCamera = scene.get_node("CustomCamera")
var hurt_lines: Array[String] = []
var hurt_lines_bag: Array[String] = []
var hurt_line_chance: float = 0.0
var death_line: String = ""
var original_material
var blink_in_progress = false
var pending_blink = false

func _ready():
	set_enemy_name(enemy_name)
	$EnemyHealthBar.max_value = health
	$EnemyHealthBar.value = health
	update_health_bar()
	
	background.set_enemy_texture($EnemyIcon.get_texture())
	
	original_material = $EnemyIcon.material.duplicate()

func get_difficulty() -> String:
	return difficulty

func set_difficulty(new_difficulty: String) -> void:
	difficulty = new_difficulty
	
	match difficulty:
		"Normal":
			$EnemyIcon.material = wobble_material
			$EnemyRedGlow.hide()
			nightmare_icon.hide()
		"Nightmare":
			$EnemyIcon.material = shake_material
			$EnemyRedGlow.show()
			nightmare_icon.show()

func set_eye_positions(eye_positions: Array[Vector2]) -> void:
	var eye_1_position: Vector2 = eye_positions[0]
	var eye_2_position: Vector2 = eye_positions[1]
	var eye_1 = load("res://EnemyEyeGlow.scn").instantiate()
	var eye_2 = load("res://EnemyEyeGlow.scn").instantiate()
	$EnemyIcon.add_child(eye_1)
	$EnemyIcon.add_child(eye_2)
	eye_1.set_position(eye_1_position)
	eye_2.set_position(eye_2_position)
	
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
	$EnemyNamePanel/EnemyName.set_text("[center][b][shake rate=2.0 level=1 connected=1]%s[/shake][/b][/center]" % enemy_name)
	
	if len(enemy_name) >= 19:
		var current_enemy_name_font_size: int = $EnemyNamePanel/EnemyName.get("theme_override_font_sizes/bold_font_size") if enemy_name_font_size <= 0 else enemy_name_font_size 
		$EnemyNamePanel/EnemyName.set("theme_override_font_sizes/bold_font_size",enemy_name_font_size)
	
func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	
	$EnemyHealthBar.max_value = max_health
	
func set_health(new_health: int) -> void:
	health = new_health
	$EnemyHealthBar.value = health
	
	update_health_bar()
	
func get_max_health() -> int:
	return max_health
	
func get_health() -> int:
	return health
	
func add_health(added_health: int) -> void:
	health = min(max_health, health + added_health)
	
	update_health_bar()
	
func set_enemy_icon_texture(new_texture: Texture2D) -> void:
	$EnemyIcon.set_texture(new_texture)
	
func add_to_debuff_activate_queue(debuff: Debuff) -> void:
	debuff_activate_queue.append(debuff_activate_queue)
	
func add_debuff(new_debuff: Debuff) -> void:
	if new_debuff.get_parent() != self:
		add_child(new_debuff)
			
	new_debuff.set_target(self)
			
	$DebuffContainer.add_debuff(new_debuff)

func add_buff(new_buff: Buff) -> void:
	if new_buff.get_parent() != self:
		add_child(new_buff)
			
	new_buff.set_target(self)
			
	$EnemyBuffsContainer.add_buff(new_buff)
	
	

func blink_white() -> void:
	if blink_in_progress:
		pending_blink = true
		return

	blink_in_progress = true
	var previous_material = $EnemyIcon.material
	var blink_material = previous_material.duplicate()
	blink_material.shader = blink_shader
	$EnemyIcon.material = blink_material
	blink_material.set_shader_parameter("blink_strength", 1.0)

	await get_tree().create_timer(0.05).timeout

	blink_material.set_shader_parameter("blink_strength", 0.0)
	$EnemyIcon.material = previous_material
	blink_in_progress = false

	if pending_blink:
		pending_blink = false
		blink_white()

func get_debuffs() -> Array:
	return $DebuffContainer.get_debuffs()

func is_animating() -> bool:
	return animating

func get_buffs() -> Array[Buff]:
	var buffs: Array[Buff] = []
	for buff_panel: BuffPanel in $EnemyBuffsContainer.get_children():
		buffs.append(buff_panel.get_buff())
	return buffs
	
func activate_on_play_buffs() -> void:
	animating = true
	for buff: Buff in get_buffs():
		if buff.is_activated_on_card_play():
			await get_tree().create_timer(0.25).timeout
			buff.activate()
	animating = false
	
func activate_on_hurt_buffs() -> void:
	animating = true
	for buff: Buff in get_buffs():
		if buff.is_activated_on_target_hurt():
			await get_tree().create_timer(0.25).timeout
			buff.activate()
	animating = false
	
func activate_on_hurt_debuffs() -> void:
	animating = true
	for debuff in get_debuffs().duplicate():
		if is_instance_valid(debuff) and not debuff.is_queued_for_deletion() and debuff.is_activated_on_hurt():
			await get_tree().create_timer(0.25).timeout
			await debuff.activate()
	animating = false

func activate_on_card_play_debuffs() -> void:
	animating = true
	for debuff: Debuff in get_debuffs().duplicate():
		if  is_instance_valid(debuff) and not debuff.is_queued_for_deletion() and debuff.is_activated_on_card_play():
			await get_tree().create_timer(0.25).timeout
			await debuff.activate()
	animating = false

func create_damage_label(hurt_amount: int) -> void:
	var damage_label: RichTextLabel = load("res://Scenes/DamageLabel.scn").instantiate()
	damage_label.set_damage(hurt_amount)
	add_child(damage_label)
	damage_label.global_position = $DamageLabelSpawn.global_position
	damage_label.float_up()

func create_hurt_text(hurt_text_message: String) -> bool:
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

	return true
	
func fade_away(texture: TextureRect) -> bool:
	var tween = get_tree().create_tween()
	tween.tween_property(texture, "self_modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	await tween.finished#print("fading away " + texture.name)
	return true
	
func fade_in(texture: TextureRect) -> bool:
	var tween = get_tree().create_tween()
	texture.self_modulate.a = 0.0
	texture.show()
	tween.tween_property(texture, "self_modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return true
	
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
	
	update_health_bar()
	
	if health <= 0:
		audio_handler.play_sfx("WinSFX")
		
		if not death_line.is_empty():
			await create_hurt_text(death_line)
			
		await get_tree().create_timer(0.75).timeout
		#await fade_away($EnemyIcon)
		$EnemyIcon.hide()
		fade_in($DefeatIcon)
		await get_tree().create_timer(0.25).timeout
			
		die()
	
	
	while background.cards_are_playing():
		await get_tree().create_timer(0.5).timeout

	scene.check_game_over()
	
func update_health_bar() -> void:
	$EnemyHealthBar.value = health
	$EnemyHealthBar/HealthText.set_text("[center][b][shake rate=2.0 level=1 connected=1]%d/%d[/shake][/b][/center]" % [health, $EnemyHealthBar.max_value])

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
	
func set_death_line(new_death_line: String) -> void:
	death_line = new_death_line
	
func die() -> void:
	#$DefeatIcon.show()
	#$EnemyIcon.hide()
	dead = true
	emit_signal("died")
