extends Resource
class_name EffectParameter

## Defines a user-configurable parameter for an EffectTemplate
## Handles type conversions and provides UI hints
const BUFF_SCENES = {
	"Blood": "res://Scenes/BloodBuff.scn",
	#"Buff": "res://Scenes/Buff.scn",
	"Charge": "res://Scenes/ChargeBuff.scn",
	"Copy": "res://Scenes/CopyBuff.scn",
	"Corrode": "res://Scenes/CorrodeBuff.scn",
	"Critical": "res://Scenes/CriticalBuff.scn",
	#"Debuff": "res://Scenes/Debuff.scn",
	"Discount": "res://Scenes/DiscountBuff.scn",
	"Doom": "res://Scenes/DoomBuff.scn",
	"Free": "res://Scenes/FreeBuff.scn",
	#"Lifesteal": "res://Scenes/LifestealBuff.scn",
	#"ModifyAttack": "res://Scenes/ModifyAttackBuff.scn",
	"Poison": "res://Scenes/PoisonBuff.scn",
	"Regen": "res://Scenes/RegenBuff.scn",
	"Repeat": "res://Scenes/RepeatBuff.scn",
	"Retaliate": "res://Scenes/RetaliateBuff.scn",
	"Return": "res://Scenes/ReturnCardToHandBuff.scn",
	"Sharp": "res://Scenes/SharpBuff.scn",
	"Shield": "res://Scenes/ShieldBuff.scn",
	"Trash": "res://Scenes/TrashBuff.scn",
	"Vulnerable": "res://Scenes/VulnerableDebuff.scn"
}

enum ParameterType {
	INT,
	FLOAT,
	BOOL,
	STRING,
	ENUM,           # Dropdown selection
	FILE_SCENE,     # Scene file picker
	BUFF_TYPE,      # Curated buff selection
	CARD_TYPE,      # Curated card selection
	TARGET_TYPE     # Enemy/Self/Random selection
}

@export var parameter_name: String  # Internal property name
@export var display_name: String    # User-facing label
@export var description: String     # Tooltip/help text
@export var parameter_type: ParameterType
@export var min_value: float = -1000.0
@export var max_value: float = 1000.0
@export var step: float = 1.0

# For ENUM type
@export var enum_options: Array[String] = []

# For FILE_SCENE type
@export var file_filter: String = "*.scn"

# Default value (not exported to avoid Variant type issues)
var default_value = null

func _init(
	p_name: String = "",
	p_display: String = "",
	p_type: ParameterType = ParameterType.INT,
	p_default: Variant = 0
) -> void:
	parameter_name = p_name
	display_name = p_display if not p_display.is_empty() else p_name.capitalize()
	parameter_type = p_type
	default_value = p_default

func get_value_from_ui(ui_value: Variant) -> Variant:
	"""Converts UI value to the actual type needed by CardEffect"""
	match parameter_type:
		ParameterType.INT:
			return int(ui_value)
		ParameterType.FLOAT:
			return float(ui_value)
		ParameterType.BOOL:
			return bool(ui_value)
		ParameterType.STRING:
			return str(ui_value)
		ParameterType.ENUM:
			# UI returns index, convert to enum value or string
			if ui_value is int and ui_value < enum_options.size():
				return enum_options[ui_value]
			return ui_value
		ParameterType.FILE_SCENE:
			# UI returns path string, load the scene
			if ui_value is String and not ui_value.is_empty():
				return load(ui_value)
			return null
		ParameterType.BUFF_TYPE:
			# Convert buff name to scene path
			return get_buff_scene(str(ui_value))
		ParameterType.CARD_TYPE:
			# Convert card name to scene path
			return get_card_scene(str(ui_value))
		ParameterType.TARGET_TYPE:
			# Convert target name to string
			return str(ui_value)

	return ui_value

func get_buff_scene(buff_name: String) -> PackedScene:
	"""Maps buff names to scene files"""


	if BUFF_SCENES.has(buff_name):
		return load(BUFF_SCENES[buff_name])
	return null

func get_card_scene(_card_name: String) -> PackedScene:
	"""Maps card names to scene files"""
	# This would be populated from available card scenes
	# For now, return null - will be implemented when needed
	return null

func get_available_options() -> Array[String]:
	"""Returns available options for selection-based parameters"""
	match parameter_type:
		ParameterType.ENUM:
			return enum_options
		ParameterType.BUFF_TYPE:
			var buff_scenes_str_keys: Array[String] = []
			for key in BUFF_SCENES.keys():
				buff_scenes_str_keys.append(str(key))
				
			return buff_scenes_str_keys
		ParameterType.TARGET_TYPE:
			return ["Enemy", "Self", "Random"]
		ParameterType.CARD_TYPE:
			# Would scan available cards - placeholder for now
			return ["Strike", "Defend", "Bash"]

	return []
