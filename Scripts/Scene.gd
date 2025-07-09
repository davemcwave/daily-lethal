extends Control
class_name Scene

signal checked_for_game_over
signal card_count_incremented

@onready var enemy = get_node("Enemy")
@onready var health = get_node("Health")
@onready var background = get_node("/root/Background")
@onready var deck: Deck = get_node("Deck")
@export_file("*.scn") var puzzle_scene
@export var override_puzzle_date: bool = false
var starting_card_amount: int = 3
var card_count: int = 0
var last_card_effects: Array[CardEffect] = []
var last_card_scene_file_path: String = ""
var last_card_backup: Card = null
var checking_for_game_over: bool = false
var game_over: bool = false
var puzzle: Puzzle = null
@onready var url_capturer: URLCapturer = $URLCapturer
@onready var next_puzzle_button = $NextPreviousPuzzleButtonContainer/NextPuzzleButton
@onready var previous_puzzle_button = $NextPreviousPuzzleButtonContainer/PreviousPuzzleButton

func _ready():
	#print("Latest Releasable Puzzle: %s" % get_latest_releasable_puzzle(get_files_in_folder("res://Scenes/Puzzles")))
	if override_puzzle_date:
		var current_puzzle: Puzzle = load(puzzle_scene).instantiate()
		set_puzzle(current_puzzle)
	elif url_capturer.is_test_puzzle():
		var new_puzzle: Puzzle = load(puzzle_scene).instantiate()
		new_puzzle.set_test_puzzle(true)
		set_puzzle(new_puzzle)
	elif url_capturer.has_today():
		var latest_releaseable_puzzle: Puzzle = load(get_latest_releasable_puzzle()).instantiate()
		set_puzzle(latest_releaseable_puzzle)
	elif url_capturer.has_puzzle_date():
		if puzzle_exists_with_date(url_capturer.get_puzzle_date()):
			var current_puzzle: Puzzle = load(get_puzzle_scene_that_starts_with(url_capturer.get_puzzle_date())).instantiate()
			if is_puzzle_is_releasable(current_puzzle):
				set_puzzle(current_puzzle)
			else:
				get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	elif not background.get_puzzle_scene().is_empty():
		var current_puzzle: Puzzle = load(background.get_puzzle_scene()).instantiate()
		if is_puzzle_is_releasable(current_puzzle):
			set_puzzle(current_puzzle)
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	else:
		var current_puzzle: Puzzle = load(puzzle_scene).instantiate()
		if is_puzzle_is_releasable(current_puzzle):
			set_puzzle(current_puzzle)
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	
	background.add_attempt()
	
	call_deferred("draw_starting_cards")
	
func get_latest_releasable_puzzle() -> String:
	var path_list: Array = get_files_in_folder("res://Scenes/Puzzles")
	var latest_path := ""
	var latest_time := 0

	for path: String in path_list:
		if not path.ends_with(".scn"):
			continue
			
		var filename = path.get_file()
		var date_str = filename.substr(0, 10)  # e.g., "2025-04-23"
		var datetime_str = date_str + "T00:00:00Z"
		var timestamp = Time.get_unix_time_from_datetime_string(datetime_str)
		var puzzle: Puzzle = load(path).instantiate()
		if timestamp > latest_time and is_puzzle_is_releasable(puzzle):
			latest_time = timestamp
			latest_path = path

		
	return latest_path

func get_unix_timestamp_from_iso_date_string(iso_date_string: String) -> int:
	var iso_date_string_split: Array = iso_date_string.split("-")
	var year: int = int(iso_date_string_split[0])
	var month: int = int(iso_date_string_split[1])
	var day: int = int(iso_date_string_split[2])
	var date_dict = {
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	var date_in_unix_time: int = Time.get_unix_time_from_datetime_dict(date_dict)
	return date_in_unix_time


func is_puzzle_is_releasable(puzzle: Puzzle) -> bool:
	var puzzle_release_date_unix: int = get_unix_timestamp_from_iso_date_string(puzzle.get_puzzle_date())
	var now_date_unix: int = Time.get_unix_time_from_datetime_dict(get_now_timestamp())
	
	#print("%s is before %s? %s!" % [puzzle.get_puzzle_date(), Time.get_datetime_string_from_datetime_dict(get_now_timestamp(), false).split("T")[0], puzzle_release_date_unix <= now_date_unix])
	return puzzle_release_date_unix <= now_date_unix
		
func get_now_timestamp():
	var now = Time.get_datetime_dict_from_system(true)
	
	return now
	
func get_puzzle_scene_that_starts_with(puzzle_name_prefix: String) -> String:
	for puzzle_scene in get_files_in_folder("res://Scenes/Puzzles"):
		var puzzle_name: String = puzzle_scene.split("/")[-1].split(".scn")[0]
		if puzzle_name.begins_with(puzzle_name_prefix):
			return puzzle_scene
	return ""

func puzzle_exists_with_date(date: String) -> bool:
	var path_list: Array = get_files_in_folder("res://Scenes/Puzzles")

	for path: String in path_list:
		if not path.ends_with(".scn"):
			continue
			
		var filename = path.get_file()
		if date in filename:
			return true
	return false
	
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
	
func get_puzzle() -> Puzzle:
	return puzzle
	
func set_puzzle(new_puzzle: Puzzle) -> void:
	puzzle = new_puzzle
	#var debug_text = ""
	#for card_scene in new_puzzle.get_card_scenes():
		#debug_text += card_scene.resource_path + ", " 
	#$URLCapturer.set_text("[center][b]%s[/b][/center]" % debug_text)
	
	
	$"/root/Background".set_puzzle_date(puzzle.get_puzzle_date())
	$Enemy.set_health($URLCapturer.get_energy_health_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_enemy_health())
	$Enemy.set_enemy_name($URLCapturer.get_enemy_name_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_enemy_name())
	$Enemy.set_enemy_icon_texture(puzzle.get_enemy_icon_texture())
	$"/root/Background".set_enemy_texture(puzzle.get_enemy_icon_texture())
	for enemy_buff: Buff in puzzle.get_enemy_buffs():
		var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
		$Enemy/EnemyBuffsContainer.add_child(buff_panel)
		buff_panel.set_buff(enemy_buff)
		var target = $Health if puzzle.get_enemy_buff_target() == 'Player' else $Enemy
		enemy_buff.set_target(target)
	
	if puzzle.do_randomize_cards():
		puzzle.clear_card_scenes()
		var card_scenes: Array[Resource] = get_all_card_scenes()
		card_scenes.shuffle()
		var random_card_scenes: Array[Resource] = []
		var random_card_count: int = puzzle.get_random_card_count()
		for i in random_card_count:
			var random_index = randi() % card_scenes.size()
			random_card_scenes.append(card_scenes[random_index])
		puzzle.set_card_scenes(random_card_scenes)
	
	var card_scenes = url_capturer.get_cards_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_card_scenes()
	for card_scene in card_scenes:
		var card: Card = card_scene.instantiate()
		$Deck.add_child(card)
		#$URLCapturer.set_text("[center][b]%s[/b][/center]" % card.name)
		#await get_tree().create_timer(2.5).timeout
		card.hide()
	
	$Health.set_health($URLCapturer.get_player_health_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_player_health())
	$Energy.set_energy($URLCapturer.get_player_energy_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_player_energy())
	starting_card_amount = puzzle.get_initial_draw_amount() if puzzle.get_initial_draw_amount() > 0 else $Deck.get_child_count() 
	
	get_node("/root/Background").set_next_puzzle_scene(puzzle.get_next_puzzle_scene())
	
	if puzzle.get_next_puzzle_scene() == null:
		next_puzzle_button.hide()
	
	if puzzle.get_previous_puzzle_scene() == null:
		previous_puzzle_button.hide()
		
	if puzzle.is_test_puzzle():
		puzzle.set_initial_draw_amount(-1)

func get_all_card_scenes() -> Array[Resource]:
	var card_scenes: Array[Resource] = []
	var dir = DirAccess.open("res://Scenes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("Card.scn") and not dir.current_is_dir() and file_name != "Card.scn":
				var scene_path = "res://Scenes/" + file_name
				var packed_scene = load(scene_path)
				card_scenes.append(packed_scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	return card_scenes
	
func get_last_card_scene_file_path() -> String:
	return last_card_scene_file_path

func get_last_card_backup() -> Card:
	return last_card_backup
	
func set_last_card_effects(card: Card) -> void:
	last_card_backup = card.duplicate(DUPLICATE_USE_INSTANTIATION)
	last_card_scene_file_path = card.get_scene_file_path()
	last_card_effects = []
	for card_effect: CardEffect in card.get_card_effects():
		var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		last_card_effects.append(new_card_effect)
		add_child(new_card_effect)
	
func get_last_card_effects() -> Array[CardEffect]:
	return last_card_effects
	
func draw_starting_cards() -> void:
	var can_draw_cards: bool = deck.can_draw_cards(starting_card_amount)
	if can_draw_cards:
		deck.draw_cards(starting_card_amount)

func increment_card_count() -> void:
	card_count += 1
	emit_signal("card_count_incremented")
	
func get_card_count() -> int:
	return card_count

func disable_all_cards() -> void:
	for card: Card in get_tree().get_nodes_in_group("Cards"):
		if not card.is_discarded():
			card.set_state(Card.State.Disabled)
			card.reduce_saturation()

func is_checking_for_game_over() -> bool:
	return checking_for_game_over
	


func check_game_over() -> void:
	# Prevent overlapping checks and ignore if game already over
	if checking_for_game_over or game_over:
		return
	checking_for_game_over = true

	# Snapshot current health and enemy state
	var p_dead = health.is_dead()
	var e_dead = enemy.is_dead()

	if p_dead:
		game_over = true
		disable_all_cards()
		# Show death panel after delay
		await get_tree().create_timer(1.0).timeout
		$CanvasLayer/DeadPanel.appear()

	elif e_dead:
		game_over = true
		background.set_best_card_count(card_count)
		# Brief pause before win screen
		await get_tree().create_timer(0.75).timeout
		# If player also died in the meantime, show death instead
		if health.is_dead():
			$CanvasLayer/DeadPanel.appear()
		else:
			get_tree().change_scene_to_file("res://Scenes/EndGameScreen.scn")

	checking_for_game_over = false
