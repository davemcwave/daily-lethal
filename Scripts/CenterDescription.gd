extends Panel
class_name CenterDescription

func set_text(title: String, description: String) -> void:
	$PreviewText.set_text("[center][b][shake rate=2.0 level=1 connected=1]%s: [/shake][/b] %s[/center]" % [title, description])

func set_color(color: Color) -> void:
	modulate = color
	
	# MAKE IT BRIGHTER!
	modulate.r *= 2.0
	modulate.g *= 2.0
	modulate.b *= 2.0

	
