extends Button


func _on_pressed():
	#OS.shell_open("https://playlethal.fun/")
	open_window_in_same_tab("https://playlethal.fun/")
	
func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
