extends EffectTemplate
class_name EnergyConditionDamageTemplate

func _init() -> void:
	template_name = "energy_condition_damage"
	display_name = "Conditional Energy Damage"
	description = "Deal damage based on energy conditions"
	short_description = "Deal {damage} if energy {condition} {comparison_value}, else {if_false_damage_amount}"
	category = "Damage"
	effect_scene_path = "res://Scenes/EnergyConditionDamageCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"damage",
			"Damage (if true)",
			EffectParameter.ParameterType.INT,
			10
		),
		EffectParameter.new(
			"condition_type",
			"Condition",
			EffectParameter.ParameterType.ENUM,
			2
		),
		EffectParameter.new(
			"comparison_value",
			"Energy Threshold",
			EffectParameter.ParameterType.INT,
			0
		),
		EffectParameter.new(
			"if_false_damage_amount",
			"Damage (if false)",
			EffectParameter.ParameterType.INT,
			0
		)
	]

	# Set up parameter details
	parameters[0].description = "Damage to deal if condition is true"
	parameters[0].min_value = 0
	parameters[0].max_value = 50

	parameters[1].description = "How to compare energy"
	parameters[1].enum_options = ["Less Than", "Greater Than", "Equal To"]

	parameters[2].description = "Energy value to compare against"
	parameters[2].min_value = 0
	parameters[2].max_value = 10

	parameters[3].description = "Damage to deal if condition is false"
	parameters[3].min_value = 0
	parameters[3].max_value = 50

func _configure_effect(effect: CardEffect) -> void:
	var damage = get_config_value("damage")
	var condition = get_config_value("condition_type")
	var threshold = get_config_value("comparison_value")
	var false_damage = get_config_value("if_false_damage_amount")

	effect.set("damage", damage)
	effect.set("condition_type", condition)
	effect.set("comparison_value", threshold)
	effect.set("if_false_damage_amount", false_damage)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
