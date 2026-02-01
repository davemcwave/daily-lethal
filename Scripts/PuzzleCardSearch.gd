extends Node

@export var target_card_names: Array[String] = []
@export var require_all_cards: bool = true
@export var output_file_path: String = "res://puzzle_card_search_results.json"
@export var include_all_cards_in_output: bool = false

func _ready():
	if target_card_names.is_empty():
		push_warning("PuzzleCardSearch: target_card_names is empty. Nothing to search for.")
		return
	var normalized_targets: Array[String] = []
	for name in target_card_names:
		normalized_targets.append(name.strip_edges().to_lower())
	var matches: Array = []
	var dir := DirAccess.open("res://Scenes/Puzzles/")
	if dir == null:
		push_error("PuzzleCardSearch: Couldn't open puzzles directory.")
		return

	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.ends_with(".scn"):
			continue
		var scene_path = "res://Scenes/Puzzles/" + file
		var scene = load(scene_path)
		if scene == null:
			push_warning("PuzzleCardSearch: Failed to load %s" % scene_path)
			continue
		var puzzle: Puzzle = scene.instantiate()
		var card_names: Array[String] = []
		var normalized_card_names: Array[String] = []
		for card_scene: Resource in puzzle.get_card_scenes():
			var card: Card = card_scene.instantiate()
			var card_name: String = card.get_card_name()
			card_names.append(card_name)
			normalized_card_names.append(card_name.to_lower())
		if puzzle_matches(normalized_targets, normalized_card_names):
			var entry = {
				"puzzle_scene": scene_path,
				"matched_cards": target_card_names.duplicate()
			}
			if include_all_cards_in_output:
				entry["all_cards"] = card_names
			matches.append(entry)
	dir.list_dir_end()

	if matches.is_empty():
		print("PuzzleCardSearch: No puzzles matched %s" % target_card_names)
	else:
		print("PuzzleCardSearch: Found %d matching puzzles." % matches.size())
		for match in matches:
			print("  %s" % match["puzzle_scene"])
		write_results(matches)

func puzzle_matches(targets: Array[String], card_names: Array[String]) -> bool:
	if require_all_cards:
		for target in targets:
			if not card_names.has(target):
				return false
		return true
	else:
		for target in targets:
			if card_names.has(target):
				return true
		return false

func write_results(results: Array) -> void:
	if output_file_path.is_empty():
		return
	var file := FileAccess.open(output_file_path, FileAccess.WRITE)
	if file == null:
		push_error("PuzzleCardSearch: Failed to open %s for writing." % output_file_path)
		return
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
