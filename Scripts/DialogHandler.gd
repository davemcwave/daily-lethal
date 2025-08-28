extends Node

var player_dialog_panel
var enemy_dialog_panel
@export var dialog_play_delay: float = 0.0
@export var enabled: bool = false

func is_enabled() -> bool:
	return enabled
	
func play_dialog(dialogue_first: String, dialogue_lines: Array[String]) -> bool:
	player_dialog_panel = get_tree().get_root().get_node("Scene/CanvasLayer/PlayerDialogPanel")
	enemy_dialog_panel = get_tree().get_root().get_node("Scene/CanvasLayer/EnemyDialogPanel")
		
	var dialog_panels = [player_dialog_panel, enemy_dialog_panel]
	if dialogue_first == 'Enemy':
		dialog_panels.reverse()
		
	while dialogue_lines.size() > 0:
		var dialog_panel: DialogPanel = dialog_panels[0]
		await dialog_panel.play_dialog_text(dialogue_lines.pop_back())
		dialog_panels.reverse()
		
		await get_tree().create_timer(dialog_play_delay).timeout
	return true
