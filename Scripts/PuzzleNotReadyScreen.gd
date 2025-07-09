extends Control


func _on_subscribe_button_pressed():
	OS.shell_open("https://playlethal.beehiiv.com/subscribe")


func _on_archive_button_pressed() -> void:
	var base_url = JavaScriptBridge.eval("window.location.origin", true)
	open_window_in_same_tab(base_url + "/archive")
		
func open_window_in_same_tab(url: String) -> void:
	JavaScriptBridge.eval("window.location.href = '%s';" % url)
