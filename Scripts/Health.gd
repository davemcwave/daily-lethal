extends TextureRect
class_name Health

@export_enum("left", "right", "center") var manual_justification: String = "center"
@export var health: int = 5
@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var original_color: Color = self_modulate
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
@onready var audio_handler = get_node("/root/AudioHandler")
@export var health_amount_text: RichTextLabel

var dead: bool = false
var block: bool = false
var bounce_tween = null

func _ready():
	update_text()

func create_damage_label(hurt_amount: int, damage_message: String = "") -> void:
	var damage_label: RichTextLabel = load("res://Scenes/DamageLabel.scn").instantiate()
	damage_label.set_damage(hurt_amount, damage_message)
	scene.add_child(damage_label)
	damage_label.global_position = global_position
	damage_label.float_up(25.0)
	
func bounce() -> void:
	if is_instance_valid(bounce_tween):
		bounce_tween.stop()
		bounce_tween = null
		
	bounce_tween = get_tree().create_tween()
	var original_scale = Vector2.ONE
	scale = original_scale * 2
	bounce_tween.tween_property(self, "scale", original_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	#var original_size = size
	#size *= 2
	#tween.tween_property(self, "size", original_size, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func blink() -> void:
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = original_color

func set_health(new_health: int) -> void:
	health = new_health
	
	if health <= 0:
		dead = true
		scene.check_game_over()
		
	update_text()

func add_health(add_health_amount: int) -> void:
	set_health(health + add_health_amount)
	create_damage_label(0, "+%d" % add_health_amount)
	bounce()
	
func get_health() -> int:
	return health

func has_enough_health(cost: int) -> bool:
	return cost <= health \
		or buffs_container.has_block_buff() \
		or buffs_container.has_free_buff() \
		or buffs_container.get_discounted_cost(cost) <= health

func hurt(amount: int) -> void:
	
	if buffs_container.has_block_buff():
		create_damage_label(0, "BLOCKED!")
		buffs_container.remove_block_buff()
	else:
		health = max(health-amount,0)
		audio_handler.play_sfx("PlayerHurtSFX")
		bounce()
		blink()
		#create_damage_label(amount)
	
		if health <= 0:
			dead = true
			
		update_text()
		
		scene.check_game_over()
		
		if amount > 0:
			buffs_container.activate_buffs(Buff.ActivationType.OnHurt)
		
func is_dead() -> bool:
	return dead
	
func get_text_template() -> String:
	match manual_justification:
		"center": 
			return "[center][b]%d[/b][/center]"
		"left": 
			return "[left][b]%d[/b][/left]"
		"right": 
			return "[right][b]%d[/b][/right]"
		_:
			return "[center][b]%d[/b][/center]"
	
func update_text() -> void:
	health_amount_text.set_text(get_text_template() % health)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Health", "If this goes to 0, you lose")
		center_description.set_color(self_modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
