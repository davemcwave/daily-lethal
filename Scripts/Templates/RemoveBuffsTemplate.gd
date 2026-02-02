extends EffectTemplate
class_name RemoveBuffsTemplate

func _init() -> void:
	template_name = "remove_buffs"
	display_name = "Remove Buffs"
	description = "Remove buffs from player or enemy"
	short_description = "Remove {remove_mode} buffs"
	category = "Buff"
	effect_scene_path = "res://Scenes/RemoveBuffsCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"remove_all_buffs",
			"Remove All Buffs",
			EffectParameter.ParameterType.BOOL,
			true
		)
	]

	# Set up parameter details
	parameters[0].description = "Remove all buffs vs specific buffs"

func _configure_effect(effect: CardEffect) -> void:
	var remove_all = get_config_value("remove_all_buffs")
	effect.set("remove_all_buffs", remove_all)
	effect.set("effect_name", get_effect_name())

	# Update short description based on value
	var desc = "Remove all buffs" if remove_all else "Remove specific buffs"
	effect.set("effect_short_description", desc)
