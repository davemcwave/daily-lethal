extends Button

@onready var file_dialog: FileDialog = $FileDialog

func _on_pressed():
	file_dialog.show()
