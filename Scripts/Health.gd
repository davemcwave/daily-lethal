extends TextureRect
class_name Health

@export var health: int = 5
@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var original_color: Color = self_modulate
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
var dead: bool = false
var block: bool = false

func _ready():
	update_text()

func create_damage_label(hurt_amount: int, damage_message: String = "") -> void:
	var damage_label: RichTextLabel = load("res://Scenes/DamageLabel.scn").instantiate()
	damage_label.set_damage(hurt_amount, damage_message)
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

func add_health(add_health_amount: int) -> void:
	set_health(health + add_health_amount)
	
func get_health() -> int:
	return health
	
func hurt(amount: int) -> void:
	
	if buffs_container.has_block_buff():
		create_damage_label(0, "BLOCKED!")
		buffs_container.remove_block_buff()
	else:
		health = max(health-amount,0)
		create_damage_label(amount)
	
		if health <= 0:
			dead = true
			
		update_text()
		
		scene.check_game_over()
		
		buffs_container.activate_on_hurt_buffs()
		
func is_dead() -> bool:
	return dead
	
func update_text() -> void:
	$HealthAmountText.set_text("[center][b]%d[/b][/center]" % health)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Health", "If this goes to 0, you lose")
		center_description.set_color(self_modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
