extends Panel
class_name DiscardPileViewText

func set_text(new_text: String) -> void:
	$LastPlayedText.set_text("[center][b]%s[/b][/center]" % new_text)
