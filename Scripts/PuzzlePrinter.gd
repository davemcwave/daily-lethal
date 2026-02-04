extends Node
class_name PuzzlePrinter

## Scans all puzzle scenes and generates puzzle_cards.json
## Usage: Call update_json() to regenerate the JSON file

@export var print_on_ready: bool = false
@export var puzzles_directory: String = "res://Scenes/Puzzles/"
@export var json_file_path: String = "res://puzzle_cards.json"

func _ready() -> void:
	if print_on_ready:
		update_json()
		print_all_puzzles()

func update_json() -> void:
	print("\n========== UPDATING PUZZLE JSON ==========\n")

	var puzzle_data = scan_all_puzzles()

	if puzzle_data.is_empty():
		print("No puzzles found in %s" % puzzles_directory)
		return

	print("Found %d puzzles" % puzzle_data.size())

	# Write to JSON file
	var success = write_json(puzzle_data)

	if success:
		print("Successfully wrote to %s\n" % json_file_path)
	else:
		print("ERROR: Failed to write to %s\n" % json_file_path)

func scan_all_puzzles() -> Dictionary:
	var puzzle_data = {}
	var puzzle_files = find_all_puzzle_files()

	for puzzle_path in puzzle_files:
		var cards = get_cards_from_puzzle(puzzle_path)
		if cards != null:
			# Use just the filename as the key
			puzzle_data[puzzle_path.get_file()] = cards

	return puzzle_data

func find_all_puzzle_files() -> Array[String]:
	var puzzle_files: Array[String] = []
	var dir = DirAccess.open(puzzles_directory)

	if dir == null:
		push_error("Failed to open directory: %s" % puzzles_directory)
		return puzzle_files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".scn"):
			puzzle_files.append(puzzles_directory + file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	puzzle_files.sort()
	return puzzle_files

func get_cards_from_puzzle(puzzle_path: String) -> Array:
	# Load puzzle scene
	var puzzle_scene = load(puzzle_path)
	if puzzle_scene == null:
		push_warning("Failed to load puzzle: %s" % puzzle_path)
		return []

	var puzzle_node = puzzle_scene.instantiate()
	if puzzle_node == null:
		push_warning("Failed to instantiate puzzle: %s" % puzzle_path)
		return []

	# Get the Puzzle script/node
	var puzzle: Puzzle = null
	if puzzle_node is Puzzle:
		puzzle = puzzle_node
	else:
		# Try to find Puzzle child node
		for child in puzzle_node.get_children():
			if child is Puzzle:
				puzzle = child
				break

	if puzzle == null:
		push_warning("No Puzzle node found in: %s" % puzzle_path)
		puzzle_node.queue_free()
		return []

	# Get card names from card_scenes
	var card_names = []
	for card_scene_res in puzzle.card_scenes:
		if card_scene_res == null:
			continue

		var card_scene = card_scene_res as PackedScene
		if card_scene == null:
			card_scene = load(card_scene_res.resource_path)

		if card_scene != null:
			var card = card_scene.instantiate()
			if card != null:
				var card_name = "Unknown"
				if card.has_method("get_card_name"):
					card_name = card.get_card_name()
				elif "card_name" in card:
					card_name = card.card_name

				card_names.append(card_name)
				card.queue_free()

	puzzle_node.queue_free()
	return card_names

func write_json(data: Dictionary) -> bool:
	var json_string = JSON.stringify(data, "\t")

	var file = FileAccess.open(json_file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: %s" % json_file_path)
		return false

	file.store_string(json_string)
	file.close()
	return true

func print_all_puzzles() -> void:
	print("\n========== PUZZLE PRINTER ==========\n")

	var puzzle_data = load_puzzle_json()
	if puzzle_data.is_empty():
		print("No puzzles in JSON")
		return

	print("Found %d puzzles:\n" % puzzle_data.size())

	var puzzle_names = puzzle_data.keys()
	puzzle_names.sort()

	for puzzle_name in puzzle_names:
		var cards = puzzle_data[puzzle_name]
		print_puzzle_info(puzzle_name, cards)

	print("\n========== END PUZZLE PRINTER ==========\n")

func load_puzzle_json() -> Dictionary:
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("Failed to parse JSON: %s" % json.get_error_message())
		return {}

	return json.data

func print_puzzle_info(puzzle_name: String, cards: Array) -> void:
	var clean_name = puzzle_name.get_basename()

	if cards.is_empty():
		print("%s - No cards" % clean_name)
	else:
		print("%s - %s" % [clean_name, ", ".join(cards)])
