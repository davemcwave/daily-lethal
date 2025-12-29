extends Button

@onready var enemy_icon: TextureRect = $"../EnemyIcon"
@onready var file_dialog: FileDialog = $FileDialog

func _on_pressed():
	file_dialog.show()


func _on_file_dialog_file_selected(path):
	enemy_icon.set_texture(load(path))
	release_focus()
