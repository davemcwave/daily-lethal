extends Button


func _on_pressed():
	var base_url = JavaScriptBridge.eval("window.location.origin", true)
	open_window_in_same_tab(base_url)
		
func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
