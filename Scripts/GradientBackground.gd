extends TextureRect
class_name GradientBackground

## Same layout as the built-in two-color cards (Haunt, Spark, Potion, ...): a
## left-to-right blend, solid at the edges, mixing between 18% and 82% of the width.
const FIRST_STOP := 0.18
const LAST_STOP := 0.82

func set_colors(new_colors: PackedColorArray) -> void:
	# Every instance of this scene shares one texture; give this card its own,
	# or setting one card's colors would recolor every other gradient card.
	var gradient_texture: GradientTexture2D = get_texture().duplicate(true)
	gradient_texture.fill_from = Vector2(0, 0.5)
	gradient_texture.fill_to = Vector2(1, 0.5)
	var offsets := PackedFloat32Array()
	for i in new_colors.size():
		var t := 0.0 if new_colors.size() < 2 else float(i) / float(new_colors.size() - 1)
		offsets.append(lerpf(FIRST_STOP, LAST_STOP, t))
	gradient_texture.gradient.offsets = offsets
	gradient_texture.gradient.colors = new_colors
	set_texture(gradient_texture)
