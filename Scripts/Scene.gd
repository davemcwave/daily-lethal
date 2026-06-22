extends Control
class_name Scene

signal checked_for_game_over
signal shown_card_preview
signal buff_added(buff)
signal card_count_incremented

@onready var enemy = get_node("Enemy")
@onready var health = get_node("Health")
@onready var background = get_node("/root/Background")
@onready var deck: Deck = get_node("Deck")
@onready var hand: Hand = get_node("HandScrollContainer/Hand")
@onready var audio_handler = get_node("/root/AudioHandler")
@export_file("*.scn") var puzzle_scene
@export var override_puzzle_date: bool = false
@export var show_intro_banner: bool = true
var starting_card_amount: int = 3
var card_count: int = 0
var last_card_effects: Array[CardEffect] = []
var last_card_scene_file_path: String = ""
var last_card_backup: Card = null
var last_card_played: Card = null
var checking_for_game_over: bool = false
var game_over: bool = false
var resolving_cards: int = 0
var puzzle: Puzzle = null
var card_play_history_paths: Array[String] = []
@onready var url_capturer: URLCapturer = $URLCapturer
@onready var next_puzzle_button = $NextPreviousPuzzleButtonContainer/NextPuzzleButton
@onready var previous_puzzle_button = $NextPreviousPuzzleButtonContainer/PreviousPuzzleButton
@onready var dialog_handler = $"/root/DialogHandler"
@onready var puzzle_resolver = $"/root/PuzzleResolver"
@onready var puzzle_author_text = get_node_or_null("PuzzleAuthorText")
var dialog_fight_button
var player_dialog_panel
var enemy_dialog_panel
var black_bg
var enemy_abilities: Array[EnemyAbility] = []

func _ready():
	background.set_using_desktop_layout(_is_desktop_layout_scene())
	load_puzzle()
	
	background.add_attempt()
	
	if can_show_initial_dialog():
		await handle_initial_dialog()
	
	await draw_starting_cards()
	
	if url_capturer.has_card_order():
		await _apply_card_order_to_hand()
	
	if puzzle_resolver.is_active():
		puzzle_resolver.resolve_puzzle()

func _is_desktop_layout_scene() -> bool:
	var packed_scene_path := ""
	if has_method("get_scene_file_path"):
		packed_scene_path = get_scene_file_path()
	if packed_scene_path.is_empty():
		var current_scene = get_tree().current_scene
		if current_scene != null and current_scene.has_method("get_scene_file_path"):
			packed_scene_path = current_scene.get_scene_file_path()
	return packed_scene_path.ends_with("Scene0Desktop.scn")

func notify_card_started_playing(card: Card) -> void:
	resolving_cards += 1

func notify_card_finished_playing(card: Card) -> void:
	resolving_cards = max(resolving_cards - 1, 0)

func is_card_resolving() -> bool:
	return resolving_cards > 0

func can_show_initial_dialog() -> bool:
	return dialog_handler.is_enabled() and has_node("CanvasLayer/DialogFightButton") and puzzle.get_dialogue_lines().size() > 0

func emit_card_preview_signal() -> void:
	emit_signal('shown_card_preview')
	
func emit_buff_added_signal(buff: Buff) -> void:
	emit_signal("buff_added", buff)
	
func handle_initial_dialog() -> bool:
	dialog_fight_button = $CanvasLayer/DialogFightButton
	player_dialog_panel = $CanvasLayer/PlayerDialogPanel
	enemy_dialog_panel = $CanvasLayer/EnemyDialogPanel
	black_bg = $CanvasLayer/BlackBG
	
	enemy_dialog_panel.set_icon_texture(puzzle.get_enemy_icon_texture())
	enemy_dialog_panel.set_title_text("[b][color=red]%s[/color][/b]" % puzzle.get_enemy_name())
	
	player_dialog_panel.show()
	enemy_dialog_panel.show()
	black_bg.show()
	
	await dialog_handler.play_dialog(puzzle.get_dialogue_first(), puzzle.get_dialogue_lines())
	dialog_fight_button.show()
	audio_handler.play_sfx("HitSFX", 1.2)
	
	await dialog_fight_button.pressed
	audio_handler.play_sfx("HitSFX", 0.75)
	await get_tree().create_timer(0.25).timeout
	hide_dialog_elements()
	
	await get_tree().create_timer(0.5).timeout
	
	return true

func hide_dialog_elements() -> void:
	black_bg.hide()
	dialog_fight_button.hide()
	player_dialog_panel.hide()
	enemy_dialog_panel.hide()

func load_puzzle() -> void:
	if override_puzzle_date:
		var current_puzzle: Puzzle = load(puzzle_scene).instantiate()
		set_puzzle(current_puzzle)
	elif puzzle_resolver.is_active():
		set_puzzle(puzzle_resolver.get_puzzle())
	elif url_capturer.is_test_puzzle():
		var new_puzzle: Puzzle = load(puzzle_scene).instantiate()
		new_puzzle.set_test_puzzle(true)
		set_puzzle(new_puzzle)
	elif url_capturer.has_puzzle_date():
		if puzzle_exists_with_date(url_capturer.get_puzzle_date()):
			var current_puzzle: Puzzle = load(get_puzzle_scene_that_starts_with(url_capturer.get_puzzle_date())).instantiate()
			_debug_log_puzzle_release_status(current_puzzle, "URL puzzle date match")
			if is_puzzle_is_releasable(current_puzzle):
				set_puzzle(current_puzzle)
			else:
				get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	elif not background.get_puzzle_scene().is_empty():
		var current_puzzle: Puzzle = load(background.get_puzzle_scene()).instantiate()
		_debug_log_puzzle_release_status(current_puzzle, "Background puzzle")
		if is_puzzle_is_releasable(current_puzzle):
			set_puzzle(current_puzzle)
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	else:
		var current_puzzle: Puzzle = load(puzzle_scene).instantiate()
		_debug_log_puzzle_release_status(current_puzzle, "Default puzzle")
		if is_puzzle_is_releasable(current_puzzle):
			set_puzzle(current_puzzle)
		else:
			get_tree().change_scene_to_file("res://Scenes/PuzzleNotReadyScreen.tscn")
	
	
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

func _debug_log_puzzle_release_status(puzzle_to_check: Puzzle, label: String = "") -> void:
	if puzzle_to_check == null:
		print("[Puzzle Release Debug] %s | puzzle is null" % label)
		return
	var now_dict = get_now_timestamp()
	var now_string = Time.get_datetime_string_from_datetime_dict(now_dict, true)
	var puzzle_date = puzzle_to_check.get_puzzle_date()
	var puzzle_unix = get_unix_timestamp_from_iso_date_string(puzzle_date)
	var now_unix = Time.get_unix_time_from_datetime_dict(now_dict)
	print("[Puzzle Release Debug] %s" % label)
	print("  puzzle_date: %s" % puzzle_date)
	print("  puzzle_unix: %d" % puzzle_unix)
	print("  now: %s" % now_string)
	print("  now_unix: %d" % now_unix)
	print("  releasable: %s" % (puzzle_unix <= now_unix))
	
func set_enemy_abilities(new_enemy_abilities: Array[EnemyAbility]) -> void:
	enemy_abilities.clear()
	
	for new_enemy_ability: EnemyAbility in new_enemy_abilities:
		var enemy_ability = new_enemy_ability.duplicate(DUPLICATE_USE_INSTANTIATION)
		enemy_abilities.append(enemy_ability)
		add_child(enemy_ability)
	
func get_enemy_abilities() -> Array[EnemyAbility]:
	return enemy_abilities
	
func set_puzzle(new_puzzle: Puzzle) -> void:
	puzzle = new_puzzle
	card_play_history_paths.clear()
	background.clear_recorded_card_solutions()
	background.set_card_solution_slugs(puzzle.get_card_solution_slugs())
	#var debug_text = ""
	#for card_scene in new_puzzle.get_card_scenes():
		#debug_text += card_scene.resource_path + ", " 
	#$URLCapturer.set_text("[center][b]%s[/b][/center]" % debug_text)
	var effective_puzzle_date := puzzle.get_puzzle_date()
	if puzzle.is_test_puzzle() and url_capturer != null and url_capturer.has_puzzle_date():
		effective_puzzle_date = url_capturer.get_puzzle_date()
	
	background.set_puzzle_date(effective_puzzle_date)
	background.set_is_test_puzzle(puzzle.is_test_puzzle())
	$Enemy.set_max_health($URLCapturer.get_energy_health_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_enemy_health())
	$Enemy.set_health($URLCapturer.get_energy_health_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_enemy_health())
	$Enemy.set_enemy_name($URLCapturer.get_enemy_name_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_enemy_name())
	$Enemy.set_enemy_icon_texture(puzzle.get_enemy_icon_texture())
	$Enemy.set_hurt_lines(puzzle.get_enemy_hurt_lines())
	$Enemy.set_hurt_line_chance(puzzle.get_hurt_line_chance())
	$Enemy.set_death_line(puzzle.get_death_line())
	if puzzle.is_nightmare_difficulty() and puzzle.has_eye_positions():
		$Enemy.set_difficulty(puzzle.get_difficulty())
		$Enemy.set_eye_positions(puzzle.get_eye_positions())
		set_enemy_abilities(puzzle.get_enemy_abilities())
		
	$"/root/Background".set_enemy_texture(puzzle.get_enemy_icon_texture())
	for enemy_buff: Buff in puzzle.get_enemy_buffs():
		var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
		$Enemy/EnemyBuffsContainer.add_child(buff_panel)
		buff_panel.set_buff(enemy_buff)
		var target = $Health if puzzle.get_enemy_buff_target() == 'Player' else $Enemy
		enemy_buff.set_target(target)

	if url_capturer != null and url_capturer.has_enemy_buffs_from_url():
		_apply_url_enemy_buffs()

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
	var existing_card_index: int = 0
	for card_scene in card_scenes:
		var card: Card = card_scene.instantiate()
		if puzzle.is_test_puzzle():
			card.set_meta("card_order_token", "E%d" % existing_card_index)
			card.set_meta("card_order_source", "existing")
			card.set_meta("card_order_index", existing_card_index)
			existing_card_index += 1
		$Deck.add_child(card)
		#$URLCapturer.set_text("[center][b]%s[/b][/center]" % card.name)
		#await get_tree().create_timer(2.5).timeout
		card.hide()

	# Add custom cards from Card Lab URL parameter
	var custom_card_count = 0
	var custom_card_index: int = 0
	if url_capturer.has_custom_cards():
		var custom_cards = url_capturer.create_custom_cards()
		print("DEBUG: create_custom_cards returned %d cards" % custom_cards.size())
		for custom_card: Card in custom_cards:
			print("DEBUG: Adding custom card '%s' to deck" % custom_card.card_name)
			if puzzle.is_test_puzzle():
				custom_card.set_meta("card_order_token", "C%d" % custom_card_index)
				custom_card.set_meta("card_order_source", "custom")
				custom_card.set_meta("card_order_index", custom_card_index)
				custom_card_index += 1
			$Deck.add_child(custom_card)
			custom_card.hide()
		custom_card_count = custom_cards.size()
		print("DEBUG: Deck now has %d children, starting_card_amount will be increased by %d" % [$Deck.get_child_count(), custom_card_count])

	if url_capturer.has_card_order():
		_apply_card_order_to_deck()

	$Health.set_health($URLCapturer.get_player_health_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_player_health())
	$Energy.set_energy($URLCapturer.get_player_energy_from_test_puzzle() if puzzle.is_test_puzzle() else puzzle.get_player_energy())

	# If custom cards are present, draw all cards in deck; otherwise use puzzle's initial draw amount
	if custom_card_count > 0:
		starting_card_amount = $Deck.get_child_count()
	else:
		starting_card_amount = puzzle.get_initial_draw_amount() if puzzle.get_initial_draw_amount() > 0 else $Deck.get_child_count() 
	
	get_node("/root/Background").set_next_puzzle_scene(puzzle.get_next_puzzle_scene())
	
	if puzzle.get_next_puzzle_scene() == null:
		next_puzzle_button.hide()
	
	if puzzle.get_previous_puzzle_scene() == null:
		previous_puzzle_button.hide()
		
	if puzzle.is_test_puzzle():
		puzzle.set_initial_draw_amount(-1)

	if puzzle_author_text != null:
		var author = background.get_author_for_enemy(puzzle.get_enemy_name())
		if url_capturer != null and url_capturer.has_puzzle_creator_name():
			author = url_capturer.get_puzzle_creator_name()
		puzzle_author_text.set_author(author)

func _apply_card_order_to_deck() -> void:
	if url_capturer == null or not url_capturer.has_card_order():
		return

	var tokens: Array = url_capturer.get_card_order_tokens()
	if tokens.is_empty():
		return

	var deck_cards: Array = deck.get_cards()
	if deck_cards.is_empty():
		return

	var token_to_card: Dictionary = {}
	for card in deck_cards:
		if card.has_meta("card_order_token"):
			var token = str(card.get_meta("card_order_token"))
			token_to_card[token] = card

	var ordered_cards: Array = []
	for token in tokens:
		var normalized = str(token)
		if token_to_card.has(normalized):
			ordered_cards.append(token_to_card[normalized])

	for card in deck_cards:
		if not ordered_cards.has(card):
			ordered_cards.append(card)

	for i in range(ordered_cards.size()):
		var card: Card = ordered_cards[i]
		if card != null and card.get_parent() == deck:
			deck.move_child(card, i)

func _apply_card_order_to_hand() -> void:
	if url_capturer == null or not url_capturer.has_card_order():
		return

	var tokens: Array = url_capturer.get_card_order_tokens()
	if tokens.is_empty():
		return

	var cards_in_hand: Array = hand.get_cards()
	if cards_in_hand.is_empty():
		return

	var token_to_card: Dictionary = {}
	for card in cards_in_hand:
		if card.has_meta("card_order_token"):
			var token = str(card.get_meta("card_order_token"))
			token_to_card[token] = card

	var ordered_cards: Array = []
	for token in tokens:
		var normalized = str(token)
		if token_to_card.has(normalized):
			ordered_cards.append(token_to_card[normalized])

	for card in cards_in_hand:
		if not ordered_cards.has(card):
			ordered_cards.append(card)

	for i in range(ordered_cards.size()):
		var card: Card = ordered_cards[i]
		if card.get_parent() != hand:
			continue
		hand.move_child(card, i)
		card.z_index = i
		card.set_original_z_index(i)

	hand.queue_sort()
	await hand.reorder_cards_by_x_position()

func _apply_url_enemy_buffs() -> void:
	var buff_scene_map := {
		"Retaliate": "res://Scenes/RetaliateBuff.scn",
		"Doom": "res://Scenes/DoomBuff.scn",
	}
	for buff_data in url_capturer.get_enemy_buffs_from_url():
		var buff_name: String = buff_data.get("name", "")
		var scene_path: String = buff_scene_map.get(buff_name, "")
		if scene_path.is_empty():
			push_warning("Unknown URL enemy buff: %s" % buff_name)
			continue
		var buff_scene = load(scene_path)
		if buff_scene == null:
			push_warning("Could not load enemy buff scene: %s" % scene_path)
			continue
		var buff: Buff = buff_scene.instantiate()
		var params: Dictionary = buff_data.get("params", {})
		match buff_name:
			"Retaliate":
				buff.activation_type = Buff.ActivationType.OnHurt
				if params.has("value"):
					buff.set_damage_amount(int(params["value"]))
				var dmg: int = buff.get_damage_amount()
				buff.set_buff_name("Retaliate %d" % dmg)
			"Doom":
				buff.activation_type = Buff.ActivationType.OnCardPlay
				if params.has("value"):
					buff.set_turns_left(int(params["value"]))
		var buff_panel: BuffPanel = load("res://Scenes/BuffPanel.scn").instantiate()
		$Enemy/EnemyBuffsContainer.add_child(buff_panel)
		buff_panel.set_buff(buff)
		buff.set_target($Health)

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
	
func set_last_card_played(card: Card) -> void:
	last_card_played = card
	
func get_last_card_played():
	return last_card_played
		
func set_last_card_effects(card: Card) -> void:
	last_card_played = card
	last_card_backup = card.duplicate(DUPLICATE_USE_INSTANTIATION)
	last_card_scene_file_path = card.get_scene_file_path()
	
	# Clone a fresh backup from the PackedScene (safe; no disappearing children)
	#var ps: PackedScene = load(last_card_scene_file_path)
	#last_card_backup = ps.instantiate() if ps != null else null
	
	last_card_effects = []
	for card_effect: CardEffect in card.get_card_effects():
		var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		last_card_effects.append(new_card_effect)
		add_child(new_card_effect)

func set_last_card_effects_directly(card: Card, new_last_card_effects: Array) -> void:
	last_card_played = card
	last_card_backup = card.duplicate(DUPLICATE_USE_INSTANTIATION)
	last_card_scene_file_path = card.get_scene_file_path()
	last_card_effects = []
	for card_effect: CardEffect in new_last_card_effects:
		var new_card_effect: CardEffect = card_effect.duplicate(DUPLICATE_USE_INSTANTIATION)
		last_card_effects.append(new_card_effect)
		add_child(new_card_effect)
	
func get_last_card_effects() -> Array[CardEffect]:
	return last_card_effects
	
func draw_starting_cards() -> Array[Card]:
	print("DEBUG: draw_starting_cards called with starting_card_amount = %d" % starting_card_amount)
	print("DEBUG: deck.get_cards().size() = %d" % deck.get_cards().size())
	var can_draw_cards: bool = deck.can_draw_cards(starting_card_amount)
	print("DEBUG: can_draw_cards(%d) = %s" % [starting_card_amount, can_draw_cards])
	if can_draw_cards:
		return await deck.draw_cards(starting_card_amount)
	return []
	
func increment_card_count() -> void:
	card_count += 1
	emit_signal("card_count_incremented")

func get_card_count() -> int:
	return card_count

func add_card_played(card: Card) -> void:
	if card == null:
		return
	var card_scene_path: String = card.get_scene_file_path()
	if card_scene_path.is_empty():
		return
	card_play_history_paths.append(card_scene_path)
	var hand_index: int = -1
	if hand != null:
		var cards_in_hand: Array = hand.get_cards()
		hand_index = cards_in_hand.find(card)
	var card_instance_id: int = card.get_instance_id()
	background.record_played_card_scene_path(card_scene_path, hand_index, card_instance_id)

func get_card_play_history_paths() -> Array[String]:
	return card_play_history_paths.duplicate()

func record_cards_choose_selection(source_card: Card, populate_type: int, source_index: int, selected_card: Card) -> void:
	if selected_card == null:
		return
	var card_scene_path: String = selected_card.get_scene_file_path()
	if card_scene_path.is_empty():
		return
	var step_type: int = background.SOLUTION_STEP_TYPE_CHOOSE_HAND
	match populate_type:
		CardsChooseArea.PopulateCardsType.FromHand:
			step_type = background.SOLUTION_STEP_TYPE_CHOOSE_HAND
		CardsChooseArea.PopulateCardsType.FromDiscard:
			step_type = background.SOLUTION_STEP_TYPE_CHOOSE_DISCARD
		CardsChooseArea.PopulateCardsType.FromCreate:
			step_type = background.SOLUTION_STEP_TYPE_CHOOSE_CREATE
	background.record_cards_choose_selection(card_scene_path, source_index, step_type)

func disable_all_cards() -> void:
	for card: Card in get_tree().get_nodes_in_group("Cards"):
		if not card.is_discarded():
			card.set_state(Card.State.Disabled)
			card.reduce_saturation()

func is_checking_for_game_over() -> bool:
	return checking_for_game_over

func is_game_over() -> bool:
	return game_over

func check_game_over_because_of_enemy() -> void:
	
	# Prevent overlapping checks and ignore if game already over
	if checking_for_game_over or game_over:
		return

	if background.get_show_tutorial():
		return
		
	checking_for_game_over = true

	# Snapshot current health and enemy state
	var e_dead = enemy.is_dead()
	if e_dead:
		game_over = true
		background.set_best_card_count(card_count)
		audio_handler.play_sfx("WinSFX")
		# Brief pause before win screen
		await get_tree().create_timer(0.75).timeout
		# If player also died in the meantime, show death instead
		if health.is_dead():
			$CanvasLayer/DeadPanel.appear()
		else:
			get_tree().change_scene_to_file("res://Scenes/EndGameScreen.scn")

	checking_for_game_over = false
func check_game_over() -> void:
	# Prevent overlapping checks and ignore if game already over
	if checking_for_game_over or game_over:
		return

	if background.get_show_tutorial():
		checking_for_game_over = false
		return
	checking_for_game_over = true

	# Snapshot current health and enemy state
	var p_dead = health.is_dead()
	var e_dead = enemy.is_dead()

	if p_dead:
		game_over = true
		disable_all_cards()
		audio_handler.play_sfx("LoseSFX")
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
