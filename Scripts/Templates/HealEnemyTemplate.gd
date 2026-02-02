extends EffectTemplate
class_name HealEnemyTemplate

func _init() -> void:
	template_name = "heal_enemy"
	display_name = "Heal Enemy"
	description = "Heal the enemy"
	short_description = "Heal enemy for {heal_amount}"
	category = "Healing"
	effect_scene_path = "res://Scenes/HealEnemyCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"heal_amount",
			"Heal Amount",
			EffectParameter.ParameterType.INT,
			3
		)
	]

	# Set up parameter details
	parameters[0].description = "Amount of health to restore to enemy"
	parameters[0].min_value = 1
	parameters[0].max_value = 50

func _configure_effect(effect: CardEffect) -> void:
	var heal_amount = get_config_value("heal_amount")
	effect.set("heal_amount", heal_amount)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
