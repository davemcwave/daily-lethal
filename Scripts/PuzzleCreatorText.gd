extends RichTextLabel
class_name PuzzleAuthorText

func set_author(new_author: String) -> void:
	if new_author.is_empty():
		hide()
		
	set_text("Puzzle created by: [b]%s[/b]" % new_author)
