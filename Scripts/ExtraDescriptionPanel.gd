extends Panel

@export var shrink_font_size_character_count: int = 95

func set_text(new_text: String) -> void:
	$ExtraDescription.set_text(new_text)
	var font_size: int = 8 if len(new_text) >= shrink_font_size_character_count else 10
	$ExtraDescription.set("theme_override_font_sizes/italics_font_size", font_size)
	$ExtraDescription.set("theme_override_font_sizes/normal_font_size",font_size)
	$ExtraDescription.set("theme_override_font_sizes/bold_font_size", font_size)
