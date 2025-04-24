extends Panel
class_name BuffPreview

func set_text(title: String, description: String) -> void:
	$PreviewText.set_text("[center][b]%s: [/b] %s[/center]" % [title, description])

func set_color(color: Color) -> void:
	get_theme_stylebox("panel").bg_color = color
