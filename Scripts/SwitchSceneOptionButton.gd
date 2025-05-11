extends OptionButton

var puzzle_map = {}

func _ready():
	var puzzle_index: int = 0
	for puzzle_scene in get_files_in_folder("res://Scenes/Puzzles"):
		var puzzle_name = puzzle_scene.split("/")[-1].split(".scn")[0]
		puzzle_map[puzzle_index] = {"scene": puzzle_scene, "name": puzzle_name}
		add_item(puzzle_name, puzzle_index)
		puzzle_index += 1
		
#func _input(event):
	#if event.is_action_pressed("ui_accept"):
		#print(puzzle_index)

func get_files_in_folder(path: String) -> Array:
	var files := []
	var dir := DirAccess.open(path)
	if dir == null:
		print("Failed to open folder:", path)
		return files

	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not dir.current_is_dir():
			files.append(path.path_join(item))
		item = dir.get_next()
	dir.list_dir_end()

	return files


func _on_item_selected(index):
	var puzzle: Dictionary = puzzle_map[index]
	var puzzle_scene: String = puzzle["scene"]
	get_node("/root/Background").set_puzzle_scene(puzzle_scene)
	get_tree().reload_current_scene()
