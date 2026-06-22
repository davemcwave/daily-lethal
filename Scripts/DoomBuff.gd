extends Buff
class_name DoomBuff

@export var turns_left: int = 3

func set_turns_left(new_turns_left: int) -> void:
	turns_left = new_turns_left

func get_turns_left() -> int:
	return turns_left
	
func get_buff_name() -> String:
	return buff_name + " " + str(turns_left)
	
func reduce_turns_left(turns_less_value: int = 1) -> void:
	turns_left -= turns_less_value
	
	var buff_panel: BuffPanel = get_parent()
	
	if turns_left <= 0:
		var scene: Scene = get_tree().get_root().get_node('Scene')
		var health: Health = scene.get_node('Health')
		health.hurt(health.get_health())
		scene.check_game_over()
		buff_panel.queue_free()
		
	else:
		buff_panel.update_text()
	
func activate(context: Dictionary = {}) -> bool:
	reduce_turns_left()
	return super.activate()

func should_show_unlimited_panel() -> bool:
	return false
