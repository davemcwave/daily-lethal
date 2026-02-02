extends EffectTemplate
class_name DrawTemplate

func _init() -> void:
	template_name = "draw"
	display_name = "Draw Cards"
	description = "Draw cards from your deck"
	short_description = "Draw {card_count} card(s)"
	category = "Draw"
	effect_scene_path = "res://Scenes/DrawCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"card_count",
			"Cards to Draw",
			EffectParameter.ParameterType.INT,
			1
		)
	]

	parameters[0].description = "Number of cards to draw"
	parameters[0].min_value = 1
	parameters[0].max_value = 10

func _configure_effect(effect: CardEffect) -> void:
	var card_count = get_config_value("card_count")
	effect.set("card_count", card_count)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
