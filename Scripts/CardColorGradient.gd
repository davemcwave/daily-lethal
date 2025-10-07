extends TextureRect
class_name CardColorGradient

@onready var gradient: Gradient = texture.get_gradient()

func set_colors(color_1: Color, color_2: Color) -> void:
	gradient.set_color(0, color_1)
	gradient.set_color(1, color_2)
