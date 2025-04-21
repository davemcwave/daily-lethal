extends RichTextLabel

#func _process(delta):
	#if has_node("/root/Background"):
		#set_text("[b]is_mobile_browser: %s[/b]" % get_node("/root/Background").is_mobile_browser())
