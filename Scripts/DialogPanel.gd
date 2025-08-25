extends Panel

@onready var dialog_text: RichTextLabel = $DialogText

func _ready():
	if visible:
		play_dialog_text()

func play_dialog_text() -> bool:
	dialog_text.visible_characters = 0
	while dialog_text.visible_ratio < 1.0:
		$DialogText.visible_characters += 1
		await get_tree().create_timer(0.025).timeout
	return true
	
