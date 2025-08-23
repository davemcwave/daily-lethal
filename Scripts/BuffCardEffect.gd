extends CardEffect
class_name BuffCardEffect

@export_file("*.scn") var buff_scene
var buff: Buff = null
@export_enum("Player", "Enemy") var buff_auto_target: String
var buff_color: Color = Color.WHITE

func _ready() -> void:
	buff = load(buff_scene).instantiate()
	buffs_container = get_tree().get_root().get_node("Scene/BuffsContainer")

	if buff_auto_target == "Player":
		buff.set_target(get_tree().get_root().get_node("Scene/Health")) 
	elif buff_auto_target == "Enemy":
		buff.set_target(get_tree().get_root().get_node("Scene/Enemy")) 

func get_effect_name() -> String:
	return buff.get_buff_name()
	#
func get_effect_description() -> String:
	return buff.get_buff_description()
	
func set_buff_color(new_buff_color: Color) -> void:
	buff_color = new_buff_color
	
func get_buff() -> Buff:
	return buff
	
func apply() -> void:
	audio_handler.play_sfx("AddBuffSFX")
	audio_handler.increase_pitch_scale("AddBuffSFX", 0.25)
	buffs_container.add_buff(buff)
	emit_signal("applied")
