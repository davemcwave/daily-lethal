extends CardEffect
class_name ActivateDiscardedCardCardEffect

@export var activation_count: int = 1
@export var ignore_parent_card: bool = false
@export var trash: bool = false
@export_enum ("Top", "Bottom") var card_direction: String = "Top"
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

var card_scene_file_path = null
var card = null

func set_card(new_card) -> void:
	card = new_card
	card_scene_file_path = new_card.get_scene_file_path()

func get_card():
	return card
	
func is_card_parent() -> bool:
	if card_scene_file_path == null:
		return false
		
	var parent = get_parent()
	if parent is Card and card_scene_file_path == parent.get_scene_file_path():
		return true
	
	return false

func apply() -> bool:
	
	
	match card_direction:
		"Top":
			if discard_panel.get_last_card() != null:
				set_card(discard_panel.get_last_card())
		"Bottom":
			if discard_panel.get_first_card() != null:
				set_card(discard_panel.get_first_card())

	if card_scene_file_path == null:
		return false
		
	if is_card_parent() and ignore_parent_card:
		return false
		
	for i in range(activation_count):
		
		var temporary_card = load(card_scene_file_path).instantiate()
		temporary_card.hide()
		add_child(temporary_card)
		
		await temporary_card.apply_card_effects()
		
		temporary_card.queue_free()
		await temporary_card.tree_exited
	
	card.queue_free()
	
	return await super.apply()
