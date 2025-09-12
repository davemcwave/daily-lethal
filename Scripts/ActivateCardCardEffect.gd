extends CardEffect
class_name ActivateCardCardEffect

@export var activation_count: int = 1
@export var ignore_parent_card: bool = false
@export var trash: bool = false

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
	if card_scene_file_path == null:
		return false
		
	if is_card_parent() and ignore_parent_card:
		return false
	
	if trash:
		card.queue_free()
		await card.tree_exited
		
	var temporary_card = load(card_scene_file_path).instantiate()
	temporary_card.hide()
	add_child(temporary_card)
	
	await temporary_card.apply_card_effects()
	
	temporary_card.queue_free()
	
	
	return super.apply()
