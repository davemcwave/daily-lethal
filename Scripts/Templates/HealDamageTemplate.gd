extends EffectTemplate
class_name HealDamageTemplate

func _init() -> void:
	template_name = "heal_damage"
	display_name = "Heal then Damage"
	description = "Deal damage to enemy and heal yourself for the same amount"
	short_description = "Deal {damage} damage and heal for {damage}"
	category = "Combo"
	effect_scene_path = "res://Scenes/HealDamageCardEffect.scn"

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
	parameters[0].description = "Amount of damage to deal (and heal)"
	parameters[0].min_value = 1
	parameters[0].max_value = 50

	parameters[1].description = "Who to damage"

func _configure_effect(effect: CardEffect) -> void:
	var damage = get_config_value("damage")
	var target = get_config_value("target_name")

	effect.set("damage", damage)
	effect.set("target_name", target)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
