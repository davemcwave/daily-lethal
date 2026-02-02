extends EffectTemplate
class_name EnergyBasedDamageTemplate

func _init() -> void:
	template_name = "energy_based_damage"
	display_name = "Energy-Based Damage"
	description = "Deal damage equal to current energy and consume all energy"
	short_description = "Deal damage equal to your energy"
	category = "Damage"
	effect_scene_path = "res://Scenes/EnergyBasedDamagedCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	# EnergyBasedDamageCardEffect has no configurable parameters
	parameters = []

func _configure_effect(effect: CardEffect) -> void:
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
