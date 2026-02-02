extends EffectTemplate
class_name HealthBasedDamageTemplate

func _init() -> void:
	template_name = "health_based_damage"
	display_name = "Health-Based Damage"
	description = "Deal damage based on your current health"
	short_description = "Deal damage based on health"
	category = "Damage"
	effect_scene_path = "res://Scenes/HealthBasedDamageCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	# HealthBasedDamageCardEffect has no configurable parameters
	parameters = []

func _configure_effect(effect: CardEffect) -> void:
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
