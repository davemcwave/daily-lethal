extends Node

func _ready():
	var results := {}
	var dir := DirAccess.open("res://Scenes/Puzzles/")
	if dir == null:
		push_error("Couldn't open puzzles directory.")
		return
	
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": break
		if file.ends_with(".scn"):
			var scene_path = "res://Scenes/Puzzles/" + file
			var scene = load(scene_path)
			if scene == null:
				print("Failed to load:", scene_path)
				continue
			var inst = scene.instantiate()
			if inst.card_scenes != null:
				var card_names := []
				for card_scene in inst.get_card_scenes():
					var card: Card = card_scene.instantiate()
					card_names.append(card.get_card_name())
				results[file] = card_names
			else:
				results[file] = []
	dir.list_dir_end()
	
	# Write results to JSON
	var json_str := JSON.stringify(results, "\t")
	var file := FileAccess.open("res://puzzle_cards.json", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("✅ Wrote puzzle_cards.json successfully.")
	else:
		push_error("Failed to open puzzle_cards.json for writing.")
