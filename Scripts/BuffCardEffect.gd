extends CardEffect
class_name BuffCardEffect

@export_file("*.scn") var buff_scene
@export var buff_node: Buff = null
var buff: Buff = null
@export_enum("Player", "Enemy") var buff_auto_target: String
var buff_color: Color = Color.WHITE

func _ready() -> void:
	buffs_container = get_tree().get_root().get_node("Scene/BuffsContainer")
	reset_buff()

func get_effect_name() -> String:
	if buff == null:
		return name
	else:
		return buff.get_buff_name()
	#
func get_effect_description() -> String:
	if buff == null:
		return ""
		
	return buff.get_buff_description()
	
func set_buff_color(new_buff_color: Color) -> void:
	buff_color = new_buff_color
	
func get_buff() -> Buff:
	return buff
	
func reset_buff() -> void:
	if buff_node != null:
		buff = buff_node
	else:
		buff = load(buff_scene).instantiate()

	if buff_auto_target == "Player":
		buff.set_target(get_tree().get_root().get_node("Scene/Health")) 
	elif buff_auto_target == "Enemy":
		buff.set_target(get_tree().get_root().get_node("Scene/Enemy")) 
	
func apply() -> bool:
	audio_handler.play_sfx("AddBuffSFX")
	audio_handler.increase_pitch_scale("AddBuffSFX", 0.25)
	buffs_container.add_buff(buff.duplicate(DUPLICATE_USE_INSTANTIATION))
	return super.apply()
