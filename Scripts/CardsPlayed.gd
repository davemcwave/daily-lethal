extends TextureRect
class_name CardsPlayed

signal cards_played_modified(cards_played_count)

@export_enum("left", "right", "center") var manual_justification: String = "center"
var cards_played_count: int = 0
@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")
@onready var original_color: Color = self_modulate
@onready var scene: Scene = get_parent()
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")
@export var card_count_text: RichTextLabel
var bounce_tween = null


func _ready():
	update_text()
	scene.connect("card_count_incremented", add_cards_played.bind(1))
	
func blink() -> void:
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = original_color

func get_cards_played_count() -> int:
	return cards_played_count
	
func set_cards_played_count(new_cards_played_count: int) -> void:
	cards_played_count = new_cards_played_count
	emit_signal("cards_played_modified", cards_played_count)
	update_text()
	
func bounce() -> void:
	if is_instance_valid(bounce_tween):
		bounce_tween.stop()
		bounce_tween = null
		
	bounce_tween = get_tree().create_tween()
	var original_scale = Vector2.ONE
	scale = original_scale * 2
	bounce_tween.tween_property(self, "scale", original_scale, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func add_cards_played(additional_cards_played: int) -> void:
	cards_played_count += additional_cards_played
	emit_signal("cards_played_modified", cards_played_count)
	bounce()
	blink()
	update_text()

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
	card_count_text.set_text(get_text_template() % cards_played_count)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Cards Played Count", "Total number of cards you've played")
		center_description.set_color(Color('0050f4'))
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()


func _on_mouse_entered():
	center_description.set_text("Cards Played Count", "Total number of cards you've played")
	center_description.set_color(Color('0050f4'))
	center_description.show()


func _on_mouse_exited():
	center_description.hide()
