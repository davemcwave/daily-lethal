extends Panel

func set_title(new_title: String) -> void:
	$TitlePanel/Title.set_text("[center]%s[/center]" % new_title)
	
func set_description(new_description: String) -> void:
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % new_description)

func set_icon_texture(new_texture: Texture2D) -> void:
	$IconPanel/Icon.set_texture(new_texture)
