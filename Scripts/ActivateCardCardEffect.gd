extends CardEffect
class_name ActivateCardCardEffect

@export var activation_count: int = 1
@export var ignore_parent_card: bool = false
var card_scene_file_path = null

func set_card(new_card) -> void:
	card_scene_file_path = new_card.get_scene_file_path()

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
	
	var card = load(card_scene_file_path).instantiate()
	card.hide()
	add_child(card)
	
	print("%s applying effects for card %s" % [get_effect_name(), card.get_card_name()])
	await card.apply_card_effects()
	card.queue_free()
	
	#for card_effect: CardEffect in card.get_card_effects(true):
		#var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		#add_child(new_card_effect)
		#
		#for i in range(activation_count):
			#await new_card_effect.apply()
			#
			#if new_card_effect.does_require_player_input():
				#await new_card_effect.player_input_finished

	return super.apply()
