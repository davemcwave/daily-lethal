extends EffectTemplate
class_name BuffWithHealthTemplate

func _init() -> void:
	template_name = "buff_with_health"
	display_name = "Buff Based on Health"
	description = "Apply a buff based on current health condition"
	short_description = "Gain {fixed_stack_amount} buff stacks when health {condition} {health_threshold}"
	category = "Buff"
	effect_scene_path = "res://Scenes/BuffWithHealthCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"health_threshold",
			"Health Threshold",
			EffectParameter.ParameterType.INT,
			3
		),
		EffectParameter.new(
			"condition_type",
			"Condition Type",
			EffectParameter.ParameterType.ENUM,
			0
		),
		EffectParameter.new(
			"fixed_stack_amount",
			"Stack Amount",
			EffectParameter.ParameterType.INT,
			1
		)
	]

	# Set up parameter details
	parameters[0].description = "Health value to compare against"
	parameters[0].min_value = 1
	parameters[0].max_value = 20

	parameters[1].description = "How to compare health"
	parameters[1].enum_options = ["Less Than", "Less Than or Equal", "Greater Than",
								   "Greater Than or Equal", "Equal", "Not Equal"]

	parameters[2].description = "Number of buff stacks to apply"
	parameters[2].min_value = 1
	parameters[2].max_value = 10

func _configure_effect(effect: CardEffect) -> void:
	var threshold = get_config_value("health_threshold")
	var condition = get_config_value("condition_type")
	var stacks = get_config_value("fixed_stack_amount")

	effect.set("health_threshold", threshold)
	effect.set("condition_type", condition)
	effect.set("stack_calculation", 1)  # FixedAmount mode
	effect.set("fixed_stack_amount", stacks)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
