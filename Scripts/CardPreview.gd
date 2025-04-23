extends Panel

func clear_extra_descriptions() -> void:
	for extra_description in $ExtraDescriptions.get_children():
		extra_description.queue_free()
		
func set_title(new_title: String) -> void:
	$TitlePanel/Title.set_text("[center]%s[/center]" % new_title)
	
func set_description(new_description: String) -> void:
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % new_description)

func set_energy_cost(energy_cost: int) -> void:
	$EnergyPanel/Energy.set_text("[center]%d[/center]" % energy_cost)
	
func set_icon_texture(new_texture: Texture2D) -> void:
	$IconPanel/Icon.set_texture(new_texture)
	
func set_background_color(color: Color) -> void:
	$IconPanel.get_theme_stylebox("panel").bg_color = color
	
func add_extra_description(new_text: String) -> void:
	$ExtraDescriptions.add_description(new_text)
