extends EffectTemplate
class_name DiscardTemplate

func _init() -> void:
	template_name = "discard"
	display_name = "Discard Cards"
	description = "Discard cards from hand"
	short_description = "Discard up to {max_discard_amount} cards"
	category = "Card Manipulation"
	effect_scene_path = "res://Scenes/DiscardCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"max_discard_amount",
			"Max Cards to Discard",
			EffectParameter.ParameterType.INT,
			2
		)
	]

	# Set up parameter details
	parameters[0].description = "Maximum number of cards to discard"
	parameters[0].min_value = 1
	parameters[0].max_value = 10

func _configure_effect(effect: CardEffect) -> void:
	var discard_amount = get_config_value("max_discard_amount")
	effect.set("max_discard_amount", discard_amount)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
