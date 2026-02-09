extends TextureRect
class_name GradientBackground

func set_colors(new_colors: PackedColorArray) -> void:
	var gradient_texture: GradientTexture2D = get_texture()
	gradient_texture.gradient.colors = new_colors
