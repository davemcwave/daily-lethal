extends ColorRect
class_name CardChoiceView

signal finished_selecting_card_effect

@export var initial_card: Card = null
var selected_card_effect: CardEffect = null

func clear() -> void:
	for child in $CardEffectChoicesContainer.get_children():
		$CardEffectChoicesContainer.remove_child(child)
	
func set_card_preview(card: Card) -> void:
	$CardPreview/TitlePanel/Title.set_text("[center]%s[/center]" % card.get_card_name())
	$CardPreview/EnergyPanel/Energy.set_text("[center]%d[/center]" % card.get_energy_cost())
	$CardPreview/DescriptionPanel/Title.set_text("[center]%s[/center]" % card.get_card_description())
	$CardPreview/IconPanel/Icon.set_texture(card.get_icon_texture())
	$CardPreview/IconPanel.get("theme_override_styles/panel").bg_color = card.get_background_color()
	$TitleText.get("theme_override_styles/normal").bg_color = card.get_background_color()
	
	var card_effects_to_choose_from = []
	for card_effect: CardEffect in card.get_card_effects():
		if card_effect is PlayerChooseEffectCardEffect:
			card_effects_to_choose_from = card_effect.get_card_effects_to_choose_from()
			break
	
	var card_effect_count: int = 0
	for card_effect: CardEffect in card_effects_to_choose_from:
		var card_effect_choice_button: CardEffectChoiceButton = load("res://Scenes/CardEffectChoiceButton.scn").instantiate()
		card_effect_choice_button.set_button_text(card_effect.get_effect_short_description())
		card_effect_choice_button.set_card_effect(card_effect)
		
		if card_effect.get_effect_color() != null:
			card_effect_choice_button.set_color(card_effect.get_effect_color())
		
		$CardEffectChoicesContainer.add_child(card_effect_choice_button)
		card_effect_choice_button.connect("pressed", select_card_effect.bind(card_effect_choice_button.get_card_effect()))
		if card_effect_count < card_effects_to_choose_from.size() - 1:
			var card_effect_choice_conditional_label: CardEffectChoiceConditionLabel = load("res://Scenes/CardEffectChoiceConditionalLabel.scn").instantiate()
			$CardEffectChoicesContainer.add_child(card_effect_choice_conditional_label)
		
		card_effect_count += 1

func get_selected_card_effect() -> CardEffect:
	return selected_card_effect
	
func select_card_effect(card_effect: CardEffect) -> void:
	selected_card_effect = card_effect
	hide()
	clear()
	emit_signal("finished_selecting_card_effect")
