extends Button

@onready var background = $"/root/Background"

func _ready():
	if background.is_from_story_view():
		if has_node("Label"):
			$Label.set_text("[center][b]Puzzles[/b][/center]")
		else:
			set_text("    PUZZLES")

func _on_pressed(): 
	if background.is_web_platform():
		var base_url = JavaScriptBridge.eval("window.location.origin", true)
		open_window_in_same_tab(base_url + "/archive")
	elif background.is_from_story_view():
		get_tree().change_scene_to_file("res://Scenes/StoryView.scn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")
		
func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
