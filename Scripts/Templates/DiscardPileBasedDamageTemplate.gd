extends EffectTemplate
class_name DiscardPileBasedDamageTemplate

func _init() -> void:
	template_name = "discard_pile_based_damage"
	display_name = "Discard Pile Damage"
	description = "Deal damage based on discard pile size"
	short_description = "Damage based on discard pile"
	category = "Damage"
	effect_scene_path = "res://Scenes/DiscardPileBasedDamageCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	# DiscardPileBasedDamageCardEffect calculates damage dynamically
	parameters = []

func _configure_effect(effect: CardEffect) -> void:
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
