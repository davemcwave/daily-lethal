extends CardEffect
class_name BuffCardEffect

@export_file("*.scn") var buff_scene
var buff: Buff = null
var buffs_container: BuffsContainer


func _ready() -> void:
	buff = load(buff_scene).instantiate()
	buffs_container = get_tree().get_root().get_node("Scene/BuffsContainer")

#func get_effect_name() -> String:
	#return buff.get_buff_name()
	#
#func get_effect_description() -> String:
	#return buff.get_buff_description()
	
func apply() -> void:
	buffs_container.add_buff(buff)
