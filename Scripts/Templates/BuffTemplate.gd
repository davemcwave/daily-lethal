extends EffectTemplate
class_name BuffTemplate

func _init() -> void:
	template_name = "buff"
	display_name = "Apply Buff"
	description = "Apply a buff to yourself or an enemy"
	short_description = "Gain {stacks} {buff_type}"
	category = "Buff"
	effect_scene_path = "res://Scenes/BuffCardEffect.scn"

	super._init()

func _setup_parameters() -> void:
	parameters = [
		EffectParameter.new(
			"buff_type",
			"Buff Type",
			EffectParameter.ParameterType.BUFF_TYPE,
			"Strength"
		),
		EffectParameter.new(
			"stacks",
			"Stack Amount",
			EffectParameter.ParameterType.INT,
			1
		),
		EffectParameter.new(
			"target",
			"Apply To",
			EffectParameter.ParameterType.ENUM,
			0
		)
	]

	# Set up parameter details
	parameters[0].description = "Type of buff to apply"

	parameters[1].description = "Number of buff stacks"
	parameters[1].min_value = 1
	parameters[1].max_value = 50

	parameters[2].description = "Who receives the buff"
	parameters[2].enum_options = ["Self", "Enemy"]

func _configure_effect(effect: CardEffect) -> void:
	# Get configuration values
	var buff_type = get_config_value("buff_type")
	var stacks = get_config_value("stacks")
	var target_index = get_config_value("target")

	# Get the buff scene from EffectParameter
	var param = parameters[0]  # buff_type parameter
	var buff_scene = param.get_buff_scene(buff_type)

	if buff_scene:
		effect.set("buff_scene", buff_scene)

		# Instantiate buff to get its properties
		var buff = buff_scene.instantiate()
		if buff:
			effect.set("buff_color", buff.get("buff_color"))
			effect.set("buff_node", buff)
			buff.queue_free()

	# Set stack amount
	effect.set("buff_stacks", stacks)

	# Set target - convert enum index to boolean flags
	var is_self = (target_index == 0)
	effect.set("buff_auto_target", 0 if is_self else 1)  # Assuming 0=self, 1=enemy

	# Set effect metadata
	effect.set("effect_name", get_effect_name())
	effect.set("effect_short_description", get_effect_short_description())

func get_effect_short_description() -> String:
	"""Override to provide better description for buffs"""
	var buff_type = get_config_value("buff_type")
	var stacks = get_config_value("stacks")
	var target_index = get_config_value("target")
	var target = "yourself" if target_index == 0 else "enemy"

	return "Apply %d %s to %s" % [stacks, buff_type, target]
