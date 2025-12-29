extends Node

@export var active: bool = false
@export var cards_to_test: Array[PackedScene] = []
@export var puzzle_index: int = 0

func _ready() -> void:
	truncate_file()
	
func is_active() -> bool:
	return active

func get_puzzle() -> Puzzle:
	var puzzle = get_puzzles()[puzzle_index]
	puzzle_index += 1
	return puzzle
	
func get_puzzles() -> Array:
	var puzzles = []
	var dir := DirAccess.open("res://Scenes/Puzzles/")
	if dir == null:
		push_error("Couldn't open puzzles directory.")
		return []
	
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
			else:
				var puzzle: Puzzle = scene.instantiate()
				var has_cards_to_test: bool = not cards_to_test.is_empty() and puzzle.has_any_cards(cards_to_test)
				if (has_cards_to_test or cards_to_test.is_empty()):
					puzzles.append(puzzle)
			
	dir.list_dir_end()
	return puzzles
	
func play_card(card: Card) -> void:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	var energy: Energy = get_tree().get_root().get_node('Scene/Energy')
	for current_card: Card in hand.get_cards():
		if current_card.get_card_name() == card.get_card_name() and current_card.can_play_for_resolver():
			current_card.play()
			return

func play_card_in_choose_area(cards_choose_area: CardsChooseArea, card: Card) -> void:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	for current_card: Card in hand.get_cards():
		if current_card.get_card_name() == card.get_card_name():
			cards_choose_area.apply_action(current_card)
			cards_choose_area.close()
			return
	
func resolve_puzzle(card_play_delay_seconds: float = 1.25) -> void:
	Engine.set_time_scale(5.0)
	
	var scene: Scene = get_tree().get_root().get_node('Scene')
	var cards_choose_area: CardsChooseArea = scene.get_node('CanvasLayer/CardsChooseArea')
	var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
	var puzzle: Puzzle = scene.get_puzzle()
	
	for card_scene in puzzle.get_card_solution():
		var card: Card = card_scene.instantiate()
		
		if cards_choose_area.visible:
			play_card_in_choose_area(cards_choose_area, card)
		else:
			play_card(card)
			
		while buffs_container.is_animating():
			await get_tree().create_timer(card_play_delay_seconds).timeout
			
		await get_tree().create_timer(card_play_delay_seconds).timeout
	
	await get_tree().create_timer(2.0).timeout
	if get_tree().current_scene.name == 'EndGameScreen':
		write_result_to_file('%s:  PASS'  % puzzle.scene_file_path)
	else:
		write_result_to_file('%s:  FAIL'  % puzzle.scene_file_path)
	
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")
	
func truncate_file():
	var path = "res://puzzle-resolver-test-results.txt"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.close()
		print("File cleared.")
		
func write_result_to_file(message: String):
	var path = "res://puzzle-resolver-test-results.txt"

	# Create the file if it doesn't exist
	if not FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.WRITE)
		f.close()

	# Open for read+write and seek to end
	var file = FileAccess.open(path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()
		print("Appended to file:", message)
	else:
		push_error("Failed to open file for appending.")
