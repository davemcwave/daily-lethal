extends Resource
class_name EffectTemplate

## Base class for effect templates
## Provides user-friendly abstraction over CardEffect classes

@export var template_name: String
@export var display_name: String
@export var description: String
@export var short_description: String  # For card preview
@export var category: String  # "Damage", "Healing", "Draw", "Buff", "Modify"
@export var icon: Texture2D

# The CardEffect scene this template creates
@export_file("*.scn") var effect_scene_path: String

# User-configurable parameters
var parameters: Array[EffectParameter] = []

# Stores user configuration
var config_values: Dictionary = {}

func _init() -> void:
	_setup_parameters()

func _setup_parameters() -> void:
	"""Override this to define template parameters"""
	pass

func get_effect_name() -> String:
	"""Returns the display name for UI"""
	return display_name if not display_name.is_empty() else template_name

func get_effect_description() -> String:
	"""Returns full description"""
	return description

func get_effect_short_description() -> String:
	"""Returns short description with interpolated values"""
	return _interpolate_description(short_description)

func create_effect() -> CardEffect:
	"""Creates a configured CardEffect instance"""
	if effect_scene_path.is_empty():
		push_error("EffectTemplate: effect_scene_path is empty for %s" % template_name)
		return null

	var effect_scene = load(effect_scene_path)
	if effect_scene == null:
		push_error("EffectTemplate: Could not load scene %s" % effect_scene_path)
		return null

	var effect: CardEffect = effect_scene.instantiate()
	_configure_effect(effect)
	return effect

func _configure_effect(effect: CardEffect) -> void:
	"""Override this to apply configuration to the CardEffect instance"""
	# Default implementation: apply all config values as properties
	for param in parameters:
		if config_values.has(param.parameter_name):
			var ui_value = config_values[param.parameter_name]
			var actual_value = param.get_value_from_ui(ui_value)
			effect.set(param.parameter_name, actual_value)

func set_config_value(param_name: String, value: Variant) -> void:
	"""Sets a configuration value"""
	config_values[param_name] = value

func get_config_value(param_name: String) -> Variant:
	"""Gets a configuration value, or default if not set"""
	if config_values.has(param_name):
		return config_values[param_name]

	# Return default from parameter
	for param in parameters:
		if param.parameter_name == param_name:
			return param.default_value

	return null

func _interpolate_description(desc: String) -> String:
	"""Replaces {param_name} with actual values in description"""
	var result = desc
	for param in parameters:
		var value = get_config_value(param.parameter_name)
		var placeholder = "{%s}" % param.parameter_name
		result = result.replace(placeholder, str(value))
	return result

func get_parameters() -> Array[EffectParameter]:
	"""Returns array of configurable parameters"""
	return parameters

func clone_with_config(config: Dictionary) -> EffectTemplate:
	"""Creates a copy of this template with specific configuration"""
	var template_copy = duplicate(true)
	template_copy.config_values = config.duplicate()
	return template_copy
