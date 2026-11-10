extends RefCounted
class_name TextFit

## Card text that fits its box: the largest font size, from max_size down to
## min_size, at which the label's text (wrapped to its width) is no taller than
## its box. Measured with the font, so it works the moment the text is set (no
## frame wait). Needs the label laid out (in the tree, with a size).
static func fit(label: RichTextLabel, max_size: int, min_size: int) -> void:
	if label == null or label.size.x <= 0.0:
		return
	var box_height := _box_height(label)
	if box_height <= 0.0:
		return
	label.scroll_active = false
	var text := label.get_parsed_text()
	var font: Font = label.get_theme_font("normal_font")
	var width := label.size.x - 4.0  # RichTextLabel's own padding, and some slack
	var font_size := max_size
	while font_size > min_size and _text_height(font, text, width, font_size) > box_height:
		font_size -= 1
	for size_name in ["normal_font_size", "bold_font_size"]:
		label.add_theme_font_size_override(size_name, font_size)

## A label that grows with its text (fit_content) is as tall as its text, so
## its box is the room its anchors give it in its parent (the card's panel).
static func _box_height(label: RichTextLabel) -> float:
	var parent := label.get_parent() as Control
	if not label.fit_content or parent == null:
		return label.size.y
	return parent.size.y * (label.anchor_bottom - label.anchor_top) + label.offset_bottom - label.offset_top

static func _text_height(font: Font, text: String, width: float, font_size: int) -> float:
	var height := 0.0
	for line in text.split("\n"):
		height += font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, width, font_size).y
	return height
