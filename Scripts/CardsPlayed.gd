extends TextureRect
class_name CardsPlayed

signal cards_played_modified(cards_played_count)

var cards_played_count: int = 0
@onready var buffs_container: BuffsContainer = get_tree().get_root().get_node("Scene/BuffsContainer")
@onready var original_color: Color = self_modulate
const TEXT_TEMPLATE = "[center][b]%d[/b][/center]"
@onready var scene: Scene = get_parent()
@onready var center_description: CenterDescription = get_tree().get_root().get_node("Scene/CanvasLayer/CenterDescription")


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
	
func add_cards_played(additional_cards_played: int) -> void:
	cards_played_count += additional_cards_played
	emit_signal("cards_played_modified", cards_played_count)
	blink()
	update_text()
	
func update_text() -> void:
	$CardCountText.set_text(TEXT_TEMPLATE % cards_played_count)


func _on_gui_input(event):
	if event.is_action_pressed("select"):
		center_description.set_text("Cards Played Count", "Total number of cards you've played")
		center_description.set_color(Color('0050f4'))
		center_description.show()
	elif event.is_action_released("select"):
		center_description.hide()
