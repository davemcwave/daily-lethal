extends EffectTemplate
class_name CreateCardTemplate

func _init() -> void:
	template_name = "create_card"
	display_name = "Create Card"
	description = "Create a card and add it to hand"
	short_description = "Create a card"
	category = "Card Manipulation"
	effect_scene_path = "res://Scenes/CreateCardCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"card_to_create_scene",
			"Card to Create",
			EffectParameter.ParameterType.FILE_SCENE,
			null
		)
	]

	# Set up parameter details
	parameters[0].description = "The card scene to create"
	parameters[0].file_filter = "*.scn"

func _configure_effect(effect: CardEffect) -> void:
	var card_scene = get_config_value("card_to_create_scene")
	effect.set("card_to_create_scene", card_scene)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
