extends Node

const STEP_TYPE_PLAY := 0
const STEP_TYPE_CHOOSE_HAND := 1
const STEP_TYPE_CHOOSE_DISCARD := 2
const STEP_TYPE_CHOOSE_CREATE := 3

@export var active: bool = false
@export var cards_to_test: Array[PackedScene] = []
@export var initial_enemy_name: String = ""
@export var puzzle_index: int = 0
@export var time_scale_speed: float = 5.0
var filtered_puzzle_paths: Array[String] = []
var filtered_puzzles_cache: Array[Puzzle] = []

func _ready() -> void:
	truncate_file()
	
	if not initial_enemy_name.is_empty():
		puzzle_index = get_puzzle_index_for_enemy_name(initial_enemy_name)
		initial_enemy_name = ""

func get_puzzle_index_for_enemy_name(enemy_name: String) -> int:
	var index: int = 0
	for puzzle: Puzzle in get_puzzles():
		if puzzle.get_enemy_name() == enemy_name:
			return index
		index += 1
	return -1
	
func is_active() -> bool:
	return active
func set_filtered_puzzle_paths(new_paths: Array[String]) -> void:
	filtered_puzzle_paths.clear()
	for path in new_paths:
		if path.is_empty():
			continue
		filtered_puzzle_paths.append(path)
	filtered_puzzles_cache.clear()
	puzzle_index = 0

func get_puzzle() -> Puzzle:
	var puzzles = get_puzzles()
	if puzzles.is_empty():
		push_error("PuzzleResolver: No puzzles available to resolve.")
		return null
	if puzzle_index >= puzzles.size():
		puzzle_index = 0
	var puzzle = puzzles[puzzle_index]
	puzzle_index += 1
	return puzzle
	
func get_puzzles() -> Array:
	if not filtered_puzzle_paths.is_empty():
		if filtered_puzzles_cache.is_empty():
			for scene_path in filtered_puzzle_paths:
				if scene_path.is_empty():
					continue
				if not ResourceLoader.exists(scene_path):
					push_warning("PuzzleResolver: Filtered puzzle %s does not exist." % scene_path)
					continue
				var scene = load(scene_path)
				if scene == null:
					push_warning("PuzzleResolver: Failed to load %s" % scene_path)
					continue
				var puzzle: Puzzle = scene.instantiate()
				filtered_puzzles_cache.append(puzzle)
		return filtered_puzzles_cache

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
	
func play_card(card: Card, target_index: int = -1) -> bool:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	var cards_in_hand = hand.get_cards()
	if target_index >= 0 and target_index < cards_in_hand.size():
		var candidate: Card = cards_in_hand[target_index]
		if candidate != null and candidate.get_card_name() == card.get_card_name() and candidate.can_play_for_resolver():
			candidate.play()
			return true
	for current_card: Card in cards_in_hand:
		if current_card.get_card_name() == card.get_card_name() and current_card.can_play_for_resolver():
			current_card.play()
			return true
	return false

func resolve_puzzle(card_play_delay_seconds: float = 1.25) -> void:
	Engine.set_time_scale(time_scale_speed)
	
	var scene: Scene = get_tree().get_root().get_node('Scene')
	var cards_choose_area: CardsChooseArea = scene.get_node('CanvasLayer/CardsChooseArea')
	var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
	var puzzle: Puzzle = scene.get_puzzle()
	var enemy: Enemy = scene.get_node("Enemy")
	var card_choice_view: CardChoiceView = scene.get_node('CanvasLayer/CardChoiceView')
	var hand: Hand = scene.get_node('HandScrollContainer/Hand')
	var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
	var solution_steps: Array = puzzle.get_card_solution_steps()
	
	for step_data in solution_steps:
		var card_scene: PackedScene = step_data.get("card_scene", null)
		if card_scene == null:
			continue
		var target_index: int = int(step_data.get("hand_index", -1))
		var step_type: int = int(step_data.get("step_type", STEP_TYPE_PLAY))
		var card: Card = card_scene.instantiate()
		
		match step_type:
			STEP_TYPE_PLAY:
				if card_choice_view.visible:
					await play_card(card, target_index)
					await card_choice_view.finished_selecting_card_effect
				else:
					play_card(card, target_index)
			STEP_TYPE_CHOOSE_HAND, STEP_TYPE_CHOOSE_DISCARD, STEP_TYPE_CHOOSE_CREATE:
				await _wait_for_cards_choose_area(cards_choose_area)
				_apply_choose_step(step_type, cards_choose_area, card, target_index, hand, discard_panel)
			_:
				play_card(card, target_index)
			
		while buffs_container.is_animating():
			await get_tree().create_timer(card_play_delay_seconds).timeout
		
		while enemy.is_animating():
			await get_tree().create_timer(card_play_delay_seconds).timeout
		
		await get_tree().create_timer(card_play_delay_seconds).timeout
	
	await get_tree().create_timer(2.0).timeout
	if get_tree().current_scene.name == 'EndGameScreen':
		write_result_to_file('%s:  PASS'  % puzzle.scene_file_path)
	else:
		write_result_to_file('%s:  FAIL'  % puzzle.scene_file_path)
	
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://Scenes/Scene0Desktop.scn")
	
func _wait_for_cards_choose_area(cards_choose_area: CardsChooseArea) -> void:
	var attempts := 0
	while not cards_choose_area.visible and attempts < 120:
		await get_tree().process_frame
		attempts += 1

func _apply_choose_step(step_type: int, cards_choose_area: CardsChooseArea, card: Card, target_index: int, hand: Hand, discard_panel: DiscardPanel) -> void:
	if not cards_choose_area.visible:
		return
	var collection: Array = []
	match step_type:
		STEP_TYPE_CHOOSE_HAND:
			collection = hand.get_cards()
		STEP_TYPE_CHOOSE_DISCARD:
			collection = discard_panel.get_cards()
		STEP_TYPE_CHOOSE_CREATE:
			var card_creator: CardCreator = cards_choose_area.get_card_creator()
			collection = card_creator.get_cards()
		_:
			collection = hand.get_cards()
	var selected_card: Card = _find_card_in_collection(collection, card.get_card_name(), target_index)
	if selected_card != null:
		cards_choose_area.apply_action(selected_card)
		cards_choose_area.close()

func _find_card_in_collection(collection: Array, card_name: String, target_index: int) -> Card:
	if target_index >= 0 and target_index < collection.size():
		var candidate: Card = collection[target_index]
		if candidate != null and candidate.get_card_name() == card_name:
			return candidate
	for current_card: Card in collection:
		if current_card != null and current_card.get_card_name() == card_name:
			return current_card
	return null
	
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
