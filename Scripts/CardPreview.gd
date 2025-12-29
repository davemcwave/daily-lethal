extends Panel

@onready var original_description_font_size = $DescriptionPanel/Title.get("theme_override_font_sizes/normal_font_size")


func set_card(new_card: Card) -> void:
	set_title(new_card.get_card_name())
	set_description(new_card.get_card_description())
	set_energy_cost(new_card.get_energy_cost())

	if new_card.has_gradient_background():
		set_gradient_background_texture(new_card.get_gradient_background_texture())
	else:
		hide_gradient_background()
		
	set_icon_texture(new_card.get_icon_texture())
	set_background_color(new_card.get_background_color())
	

func clear_extra_descriptions() -> void:
	for extra_description in $ExtraDescriptions.get_children():
		extra_description.queue_free()
		
func set_title(new_title: String) -> void:
	$TitlePanel/Title.set_text("[center]%s[/center]" % new_title)
	
func set_description(new_description: String) -> void:
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % new_description)

	if len($DescriptionPanel/Title.get_parsed_text()) >= 100:
		$DescriptionPanel/Title.set("theme_override_font_sizes/normal_font_size", original_description_font_size - 2)
		
func set_energy_cost(energy_cost: int) -> void:
	$EnergyPanel/Energy.set_text("[center]%d[/center]" % energy_cost)
	
func set_icon_texture(new_texture: Texture2D) -> void:
	$IconPanel/Icon.set_texture(new_texture)
	
func set_gradient_background_texture(texture: GradientTexture2D) -> void:
	$IconPanel/GradientBackground.set_texture(texture)
	$IconPanel/GradientBackground.show()
	

func hide_gradient_background() -> void:
	$IconPanel/GradientBackground.hide()
	
func set_background_color(color: Color) -> void:
	$IconPanel.get_theme_stylebox("panel").bg_color = color
	
func add_extra_description(new_text: String) -> void:
	$ExtraDescriptions.add_description(new_text)


func _on_option_button_mouse_entered():
	pass # Replace with function body.
