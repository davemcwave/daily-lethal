extends CardEffect
class_name PlayerChooseEffectCardEffect

@export var card_effects_to_choose_from: Array[CardEffect]
@onready var card_choice_view: CardChoiceView = get_tree().get_root().get_node('Scene/CanvasLayer/CardChoiceView')
@export var card_for_preview: Card
var selected_card_effect = null
	
func apply() -> void:
	await get_tree().create_timer(0.25).timeout
	card_choice_view.set_card_preview(card_for_preview)
	card_choice_view.show()
	await card_choice_view.finished_selecting_card_effect
	selected_card_effect = card_choice_view.get_selected_card_effect()
	selected_card_effect.apply()
	emit_signal("player_input_finished")
	
func get_card_effects_to_choose_from() -> Array[CardEffect]:
	return card_effects_to_choose_from
	
func get_selected_card_effect():
	return selected_card_effect
