extends EffectTemplate
class_name GainEnergyTemplate

func _init() -> void:
	template_name = "gain_energy"
	display_name = "Gain Energy"
	description = "Gain additional energy"
	short_description = "Gain {additional_energy_amount} energy"
	category = "Energy"
	effect_scene_path = "res://Scenes/GainEnergyCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"additional_energy_amount",
			"Energy Amount",
			EffectParameter.ParameterType.INT,
			1
		)
	]

	# Set up parameter details
	parameters[0].description = "Amount of energy to gain"
	parameters[0].min_value = 1
	parameters[0].max_value = 10

func _configure_effect(effect: CardEffect) -> void:
	var energy_amount = get_config_value("additional_energy_amount")
	effect.set("additional_energy_amount", energy_amount)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
