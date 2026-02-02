extends EffectTemplate
class_name HealTemplate

func _init() -> void:
	template_name = "heal"
	display_name = "Heal"
	description = "Restore health"
	short_description = "Heal {heal_amount} HP"
	category = "Healing"
	effect_scene_path = "res://Scenes/HealCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"heal_amount",
			"Heal Amount",
			EffectParameter.ParameterType.INT,
			5
		)
	]

	parameters[0].description = "Amount of health to restore"
	parameters[0].min_value = 1
	parameters[0].max_value = 50

func _configure_effect(effect: CardEffect) -> void:
	var heal_amount = get_config_value("heal_amount")
	effect.set("heal_amount", heal_amount)
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
