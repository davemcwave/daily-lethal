extends EffectTemplate
class_name LoseEnergyTemplate

func _init() -> void:
	template_name = "lose_energy"
	display_name = "Lose Energy"
	description = "Lose energy"
	short_description = "Lose {energy_amount_loss} energy"
	category = "Energy"
	effect_scene_path = "res://Scenes/LoseEnergyCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"energy_amount_loss",
			"Energy Loss",
			EffectParameter.ParameterType.INT,
			1
		)
	]

	# Set up parameter details
	parameters[0].description = "Amount of energy to lose"
	parameters[0].min_value = 1
	parameters[0].max_value = 10

func _configure_effect(effect: CardEffect) -> void:
	var energy_loss = get_config_value("energy_amount_loss")
	effect.set("energy_amount_loss", energy_loss)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
