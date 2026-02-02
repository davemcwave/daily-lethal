extends Resource
class_name CustomCardResource

@export var card_name: String = "Custom Card"
@export var card_description: String = ""
@export var energy_cost: int = 1
@export var effect_configs: Array[Dictionary] = []

# Each dictionary in effect_configs should have:
# {
#   "effect_name": String,
#   "properties": Dictionary  # property_name -> value
# }

func add_effect_config(effect_name: String, properties: Dictionary) -> void:
	effect_configs.append({
		"effect_name": effect_name,
		"properties": properties
	})

func clear_effects() -> void:
	effect_configs.clear()

func get_effect_configs() -> Array[Dictionary]:
	return effect_configs
