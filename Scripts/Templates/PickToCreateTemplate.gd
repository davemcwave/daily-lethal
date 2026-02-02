extends EffectTemplate
class_name PickToCreateTemplate

func _init() -> void:
	template_name = "pick_to_create"
	display_name = "Pick Card to Create"
	description = "Choose a card to create"
	short_description = "Choose a card to create"
	category = "Card Manipulation"
	effect_scene_path = "res://Scenes/PickToCreateCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	# PickToCreateCardEffect has complex parameters that are scene-dependent
	parameters = []

func _configure_effect(effect: CardEffect) -> void:
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
