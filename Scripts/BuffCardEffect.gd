extends CardEffect
class_name BuffCardEffect

@export_file("*.scn") var buff_scene
var buff: Buff = null
var buffs_container: BuffsContainer
@export_enum("Player", "Enemy") var buff_auto_target: String


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
	
func apply() -> void:
	#buff.set_color(get_parent().get_node("IconPanel").get_theme_stylebox("panel").bg_color)
	buffs_container.add_buff(buff)
