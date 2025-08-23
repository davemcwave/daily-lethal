extends TextureRect
class_name Energy

@export_enum("left", "right", "center") var manual_justification: String = "center"
@export var energy_amount: int = 5
@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")
@onready var original_color: Color = self_modulate
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
@onready var health: Health 
@export var energy_amount_text: RichTextLabel
var bounce_tween = null

func _ready():
	update_energy_text()
	
func has_enough_energy(cost: int) -> bool:
	return cost <= energy_amount \
		or buffs_container.has_free_buff() \
		or buffs_container.get_discounted_cost(cost) <= energy_amount

func bounce() -> void:
	if is_instance_valid(bounce_tween):
		bounce_tween.stop()
		bounce_tween = null
		
	bounce_tween = get_tree().create_tween()
	var original_scale = Vector2.ONE
	scale = original_scale * 2
	bounce_tween.tween_property(self, "scale", original_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func get_energy_amount() -> int:
	return energy_amount

func blink() -> void:
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = original_color

func set_energy(new_energy: int) -> void:
	energy_amount = new_energy
	update_energy_text()
	
func add_energy(additional_energy_amount: int) -> void:
	energy_amount += additional_energy_amount
	blink()
	update_energy_text()
	
func use_energy(cost: int) -> void:
	energy_amount -= cost
	
	bounce()
	blink()

	update_energy_text()
	
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
	
func update_energy_text() -> void:
	energy_amount_text.set_text(get_text_template() % energy_amount)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Energy", "Amount to spend on cards, each card has its own energy cost")
		center_description.set_color(self_modulate)
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
