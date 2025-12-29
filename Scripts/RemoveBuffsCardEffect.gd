extends CardEffect
class_name RemoveBuffsCardEffect

@export var remove_all_buffs: bool = false
@export_file("*.scn") var buff_scenes
@export_enum("Player", "Enemy") var buff_auto_target: String
var buff_color: Color = Color.WHITE

func apply() -> bool:
	#audio_handler.play_sfx("AddBuffSFX")
	#audio_handler.increase_pitch_scale("AddBuffSFX", 0.25)
	
	if remove_all_buffs:
		buffs_container.remove_all_buffs()
	else:
		for buff_scene in buff_scenes:
			var buff_to_remove: Buff = load(buff_scene).instantiate()
			
			for buff: Buff in buffs_container.get_buffs(buff_to_remove.get_activation_type()):
				if buff.get_buff_name() == buff_to_remove.get_buff_name():
					buffs_container.remove_buff_by_name(buff.get_buff_name())
				
	return super.apply()
