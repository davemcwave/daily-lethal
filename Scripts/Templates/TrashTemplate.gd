extends EffectTemplate
class_name TrashTemplate

func _init() -> void:
	template_name = "trash"
	display_name = "Trash Card"
	description = "Remove cards from your deck permanently"
	short_description = "Trash {card_amount} card(s) from {trash_from_location}"
	category = "Card Manipulation"
	effect_scene_path = "res://Scenes/TrashCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"card_amount",
			"Number of Cards",
			EffectParameter.ParameterType.INT,
			1
		),
		EffectParameter.new(
			"trash_from_location",
			"Trash From",
			EffectParameter.ParameterType.ENUM,
			0
		),
		EffectParameter.new(
			"discard_pile_trash_direction",
			"Discard Direction",
			EffectParameter.ParameterType.ENUM,
			0
		)
	]

	# Set up parameter details
	parameters[0].description = "How many cards to trash"
	parameters[0].min_value = 1
	parameters[0].max_value = 10

	parameters[1].description = "Where to trash from"
	parameters[1].enum_options = ["Discard Pile", "Hand", "Self"]

	parameters[2].description = "From top or bottom of discard pile"
	parameters[2].enum_options = ["Top", "Bottom"]

func _configure_effect(effect: CardEffect) -> void:
	var card_amount = get_config_value("card_amount")
	var trash_from = get_config_value("trash_from_location")
	var direction = get_config_value("discard_pile_trash_direction")

	effect.set("card_amount", card_amount)
	effect.set("trash_from_location", parameters[1].enum_options[trash_from] if trash_from is int else trash_from)
	effect.set("discard_pile_trash_direction", parameters[2].enum_options[direction] if direction is int else direction)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
