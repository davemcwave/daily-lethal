extends EffectTemplate
class_name ReduceHealthTemplate

func _init() -> void:
	template_name = "reduce_health"
	display_name = "Reduce Health"
	description = "Reduce maximum health"
	short_description = "Reduce {target_name} health by {reduce_amount}"
	category = "Health"
	effect_scene_path = "res://Scenes/ReduceHealthCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"reduce_amount",
			"Health Reduction",
			EffectParameter.ParameterType.INT,
			1
		),
		EffectParameter.new(
			"target_name",
			"Target",
			EffectParameter.ParameterType.TARGET_TYPE,
			"Player"
		)
	]

	# Set up parameter details
	parameters[0].description = "Amount of health to reduce"
	parameters[0].min_value = 1
	parameters[0].max_value = 20

	parameters[1].description = "Who to target"
	parameters[1].enum_options = ["Player", "Enemy"]

func _configure_effect(effect: CardEffect) -> void:
	var reduce_amount = get_config_value("reduce_amount")
	var target_name = get_config_value("target_name")

	effect.set("reduce_amount", reduce_amount)
	effect.set("target_name", target_name)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
