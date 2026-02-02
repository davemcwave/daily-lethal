extends EffectTemplate
class_name TrashChooseTemplate

func _init() -> void:
	template_name = "trash_choose"
	display_name = "Choose Card to Trash"
	description = "Choose a card to permanently remove from deck"
	short_description = "Choose a card to trash"
	category = "Card Manipulation"
	effect_scene_path = "res://Scenes/TrashChooseCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	# TrashChooseCardEffect has no additional configurable parameters
	parameters = []

func _configure_effect(effect: CardEffect) -> void:
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())
