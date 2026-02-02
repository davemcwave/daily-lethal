extends EffectTemplate
class_name DamageTemplate

func _init() -> void:
	template_name = "damage"
	display_name = "Damage"
	description = "Deal damage to a target"
	short_description = "Deal {damage} damage to {target}"
	category = "Damage"
	effect_scene_path = "res://Scenes/DamageCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"damage",
			"Damage Amount",
			EffectParameter.ParameterType.INT,
			5
		),
		EffectParameter.new(
			"target_name",
			"Target",
			EffectParameter.ParameterType.TARGET_TYPE,
			"Enemy"
		)
	]

	# Set up parameter details
	parameters[0].description = "Amount of damage to deal"
	parameters[0].min_value = 0
	parameters[0].max_value = 100

	parameters[1].description = "Who to target with the damage"

func _configure_effect(effect: CardEffect) -> void:
	# Apply configuration to DamageCardEffect
	var damage = get_config_value("damage")
	var target = get_config_value("target_name")

	effect.set("damage", damage)
	effect.set("target_name", target)

	# Set the effect metadata
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
