extends Node
## Replays recorded puzzle solutions (Scenes/Puzzles/Solutions/*.tres or a
## puzzle's inline `card_solution`) and checks that each one still wins.
##
## Two modes:
## - Editor mode: set `active = true` on Scenes/PuzzleResolver.tscn and run the
##   game. Puzzles loop forever; results go to res://puzzle-resolver-test-results.txt.
## - Test-runner mode (headless, exits with a status code):
##     godot --headless --path . --fixed-fps 60 -- --puzzle-tests [options]
##   Options:
##     --only=Kraken,Goblin   only puzzles whose file name contains one of these
##     --cards=Scorch,Burn    only puzzles whose cards include one of these
##     --report=path.json     also write a JSON report (absolute or res:// path)
##     --speed=10             Engine.time_scale while resolving (default 10)
##     --timeout=20           real seconds before a puzzle attempt is failed as hung
##   Prompts a recording has no answer for (effect choices, chooser picks in old
##   recordings) are searched: up to 64 combinations (--max-choices=N) are tried per puzzle, and a
##   pass reports the choices that worked.
##   Exit code: 0 if every puzzle with a solution passed, 1 otherwise.

const STEP_TYPE_PLAY := 0
const STEP_TYPE_CHOOSE_HAND := 1
const STEP_TYPE_CHOOSE_DISCARD := 2
const STEP_TYPE_CHOOSE_CREATE := 3
# Test-runner only (from Tests/puzzle_solutions.json):
const STEP_TYPE_PICK_OPEN := 10       # pick `card_name` in whatever chooser is open
const STEP_TYPE_EFFECT := 11          # pick the effect matching `effect` (e.g. "heal")
const STEP_TYPE_CLOSE_CHOOSER := 12   # close the open chooser with nothing picked

## URL puzzles (custom-redirects.json) and their solutions.
const URL_PUZZLES_PATH := "res://custom-redirects.json"
const URL_SOLUTIONS_PATH := "res://Tests/puzzle_solutions.json"
const URL_ENTRY_PREFIX := "url:"

const GAME_SCENE_PATH := "res://Scenes/Scene0Desktop.tscn"
const PUZZLES_DIR := "res://Scenes/Puzzles/"
const RESULTS_FILE_PATH := "res://puzzle-resolver-test-results.txt"
## Not real puzzles: Puzzle.tscn is the base scene, TestPuzzle.tscn is a scratch
## placeholder for trying things out. The test runner ignores both.
const CLI_EXCLUDED_PUZZLE_FILES := ["Puzzle.tscn", "TestPuzzle.tscn"]

@export var active: bool = false
@export var cards_to_test: Array[PackedScene] = []
@export var initial_enemy_name: String = ""
@export var puzzle_index: int = 0
@export var time_scale_speed: float = 5.0
var filtered_puzzle_paths: Array[String] = []
var filtered_puzzles_cache: Array[Puzzle] = []

# --- Test-runner (CLI) mode state ---
var cli_mode: bool = false
var cli_report_path: String = ""
var cli_puzzle_timeout_msec: int = 20000
## Game seconds to wait after the last step for the win screen to appear.
var cli_outcome_timeout: float = 15.0
## Game seconds to wait for a card to show up in hand / become playable.
var cli_card_wait: float = 5.0
var cli_results: Array[Dictionary] = []
var cli_run_started_msec: int = 0
var current_puzzle_path: String = ""
var active_run_id: int = -1
var next_run_id: int = 0
var puzzle_started_msec: int = 0
var current_step_label: String = ""
## Things the runner had to work around for the current puzzle (shown in results).
var current_notes: Array[String] = []
## Search over prompts the recording has no answer for (see _answer_unrecorded_prompts).
var max_choice_attempts: int = 64
var choice_plan: Array[int] = []
var choice_option_counts: Array[int] = []
var choice_labels: Array[String] = []
var choice_attempt: int = 0
var url_puzzles: Dictionary = {}     # date -> "?cards=..." query
var url_solutions: Dictionary = {}   # date -> {"enemy_name", "steps": [...]}
var current_url_steps: Array = []
var open_chooser_picks: int = 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--puzzle-tests" in args:
		_start_cli_mode(args)
		return

	set_process(false)
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

func is_cli_mode() -> bool:
	return cli_mode

func set_filtered_puzzle_paths(new_paths: Array[String]) -> void:
	filtered_puzzle_paths.clear()
	for path in new_paths:
		if path.is_empty():
			continue
		filtered_puzzle_paths.append(path)
	filtered_puzzles_cache.clear()
	puzzle_index = 0

func get_puzzle() -> Puzzle:
	if cli_mode:
		# Load each puzzle fresh, one at a time.
		current_puzzle_path = filtered_puzzle_paths[puzzle_index]
		puzzle_index += 1
		var attempt_text := "" if choice_attempt == 0 else " (choice combination %d)" % (choice_attempt + 1)
		print("### PUZZLE %d/%d %s%s" % [puzzle_index, filtered_puzzle_paths.size(), _display_name(current_puzzle_path), attempt_text])
		if _is_url_entry(current_puzzle_path):
			# Same as the game's "?cards=" path: a placeholder puzzle flagged as a test
			# puzzle; Scene reads cards/HP/energy/buffs from URLCapturer.
			current_url_steps = _build_url_steps(_url_date(current_puzzle_path))
			var current := get_tree().current_scene
			var base_puzzle_path = current.puzzle_scene if current is Scene else PUZZLES_DIR + "Puzzle.tscn"
			var url_puzzle: Puzzle = load(base_puzzle_path).instantiate()
			url_puzzle.set_test_puzzle(true)
			return url_puzzle
		var scene_puzzle: Puzzle = load(current_puzzle_path).instantiate()
		current_url_steps = []
		if scene_puzzle.get_card_solution().is_empty():
			current_url_steps = _build_url_steps(current_puzzle_path.get_file().left(10))
		return scene_puzzle

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
	for scene_path in _list_puzzle_paths():
		var scene = load(scene_path)
		if scene == null:
			print("Failed to load:", scene_path)
			continue
		var puzzle: Puzzle = scene.instantiate()
		var has_cards_to_test: bool = not cards_to_test.is_empty() and puzzle.has_any_cards(cards_to_test)
		if (has_cards_to_test or cards_to_test.is_empty()):
			puzzles.append(puzzle)
	return puzzles

func _list_puzzle_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(PUZZLES_DIR)
	if dir == null:
		push_error("Couldn't open puzzles directory.")
		return paths
	for file in dir.get_files():
		if file.ends_with(".tscn"):
			paths.append(PUZZLES_DIR + file)
	paths.sort()
	return paths

func play_card(card: Card, target_index: int = -1) -> bool:
	var playable: Card = _find_playable_card_in_hand(card.get_card_name(), target_index)
	if playable == null:
		return false
	playable.play()
	return true

func _find_playable_card_in_hand(card_name: String, target_index: int = -1) -> Card:
	var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')
	var cards_in_hand = hand.get_cards()
	if target_index >= 0 and target_index < cards_in_hand.size():
		var candidate: Card = cards_in_hand[target_index]
		if candidate != null and candidate.get_card_name() == card_name and candidate.can_play_for_resolver():
			return candidate
	for current_card: Card in cards_in_hand:
		if current_card.get_card_name() == card_name and current_card.can_play_for_resolver():
			return current_card
	return null

func resolve_puzzle(card_play_delay_seconds: float = 1.25) -> void:
	if cli_mode:
		await _resolve_puzzle_cli(card_play_delay_seconds)
		return

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

	for step_number in solution_steps.size():
		var step_data: Dictionary = solution_steps[step_number]
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
				var close_after: bool = not _more_picks_follow(solution_steps, step_number)
				_apply_choose_step(step_type, cards_choose_area, card, target_index, hand, discard_panel, close_after)
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
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _wait_for_cards_choose_area(cards_choose_area: CardsChooseArea) -> void:
	var attempts := 0
	while not cards_choose_area.visible and attempts < 120:
		await get_tree().process_frame
		attempts += 1

func _apply_choose_step(step_type: int, cards_choose_area: CardsChooseArea, card: Card, target_index: int, hand: Hand, discard_panel: DiscardPanel, close_after: bool = true) -> bool:
	if not cards_choose_area.visible:
		return false
	var collection: Array = _get_choose_collection(step_type, cards_choose_area, hand, discard_panel)
	var selected_card: Card = _find_card_in_collection(collection, card.get_card_name(), target_index)
	if selected_card == null:
		return false
	_mark_chosen(cards_choose_area, selected_card)
	if close_after:
		_confirm_chooser(cards_choose_area)
	return true

func _more_picks_follow(steps: Array, step_number: int) -> bool:
	# A chooser that allows several picks (e.g. Armory: "Choose 2") is recorded as
	# consecutive choose steps of the same type; keep it open between them.
	if step_number + 1 >= steps.size():
		return false
	var this_type: int = int(steps[step_number].get("step_type", STEP_TYPE_PLAY))
	var next_type: int = int(steps[step_number + 1].get("step_type", STEP_TYPE_PLAY))
	return next_type == this_type and this_type != STEP_TYPE_PLAY

func _mark_chosen(cards_choose_area: CardsChooseArea, card: Card) -> bool:
	# Same as clicking that card in the chooser. The chooser shows copies of the
	# offered cards carrying the original's id; prefer that copy, else another
	# unchosen copy with the same name (e.g. the second of two Gambits).
	var fallback: Card = null
	for shown in cards_choose_area.cards_container.get_children():
		if not (shown is Card) or shown.is_chosen():
			continue
		if shown.get_id() == card.get_id():
			shown.show_choosing_button()
			return true
		if fallback == null and shown.get_card_name() == card.get_card_name():
			fallback = shown
	if fallback != null:
		fallback.show_choosing_button()
		return true
	return false

func _confirm_chooser(cards_choose_area: CardsChooseArea) -> void:
	# Same as pressing the chooser's action button: applies (and records) the
	# chosen cards, then closes it. With nothing chosen it records "picked nothing".
	cards_choose_area._on_action_button_pressed()

func _get_choose_collection(step_type: int, cards_choose_area: CardsChooseArea, hand: Hand, discard_panel: DiscardPanel) -> Array:
	match step_type:
		STEP_TYPE_CHOOSE_HAND:
			return hand.get_cards()
		STEP_TYPE_CHOOSE_DISCARD:
			return discard_panel.get_cards()
		STEP_TYPE_CHOOSE_CREATE:
			var card_creator: CardCreator = cards_choose_area.get_card_creator()
			return card_creator.get_cards()
	return hand.get_cards()

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
	var file = FileAccess.open(RESULTS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.close()
		print("File cleared.")

func write_result_to_file(message: String):
	# Create the file if it doesn't exist
	if not FileAccess.file_exists(RESULTS_FILE_PATH):
		var f = FileAccess.open(RESULTS_FILE_PATH, FileAccess.WRITE)
		f.close()

	# Open for read+write and seek to end
	var file = FileAccess.open(RESULTS_FILE_PATH, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()
		print("Appended to file:", message)
	else:
		push_error("Failed to open file for appending.")

# =============================================================================
# Test-runner (CLI) mode
# =============================================================================

func _start_cli_mode(args: PackedStringArray) -> void:
	cli_mode = true
	active = true
	time_scale_speed = 10.0
	var only_filters: Array[String] = []
	var card_filters: Array[String] = []
	for arg in args:
		if arg.begins_with("--only="):
			only_filters = _split_filter(arg.trim_prefix("--only="))
		elif arg.begins_with("--cards="):
			card_filters = _split_filter(arg.trim_prefix("--cards="))
		elif arg.begins_with("--report="):
			cli_report_path = arg.trim_prefix("--report=")
		elif arg.begins_with("--speed="):
			time_scale_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--max-choices="):
			max_choice_attempts = maxi(1, int(arg.trim_prefix("--max-choices=")))
		elif arg.begins_with("--timeout="):
			cli_puzzle_timeout_msec = int(float(arg.trim_prefix("--timeout=")) * 1000.0)

	_load_url_puzzles()
	var to_run: Array[String] = []
	for path in _list_puzzle_paths():
		if path.get_file() in CLI_EXCLUDED_PUZZLE_FILES:
			continue
		var file_key := path.get_file().to_lower()
		if not only_filters.is_empty() and not only_filters.any(func(f): return file_key.contains(f)):
			continue
		var puzzle: Puzzle = load(path).instantiate()
		var include := true
		if not card_filters.is_empty():
			include = _puzzle_has_card_matching(puzzle, card_filters)
		var has_recorded: bool = not puzzle.get_card_solution().is_empty()
		puzzle.free()
		if not include:
			continue
		# A recorded solution wins; otherwise use a submitted one from the JSON file.
		var submitted: Dictionary = url_solutions.get(path.get_file().left(10), {})
		if has_recorded:
			to_run.append(path)
		elif submitted.has("skip"):
			_add_result(path, "SKIP", str(submitted["skip"]), 0, 0)
		elif not submitted.is_empty():
			to_run.append(path)
		else:
			_add_result(path, "SKIP", "no recorded or submitted solution", 0, 0)

	# URL puzzles: every date in custom-redirects.json.
	var dates: Array = url_puzzles.keys()
	dates.sort()
	for date in dates:
		var entry: String = URL_ENTRY_PREFIX + date
		var name_key := _display_name(entry).to_lower()
		if not only_filters.is_empty() and not only_filters.any(func(f): return name_key.contains(f)):
			continue
		if not card_filters.is_empty():
			var url_cards := _url_card_keys(url_puzzles[date])
			if not card_filters.any(func(f): return url_cards.any(func(c): return c == f or c.contains(f))):
				continue
		if url_solutions.has(date) and url_solutions[date].has("skip"):
			_add_result(entry, "SKIP", str(url_solutions[date]["skip"]), 0, 0)
		elif url_solutions.has(date):
			to_run.append(entry)
		else:
			_add_result(entry, "SKIP", "no solution in Tests/puzzle_solutions.json", 0, 0)

	set_filtered_puzzle_paths(to_run)
	_prepare_next_puzzle()
	cli_run_started_msec = Time.get_ticks_msec()
	print("PUZZLE TESTS: %d to run, %d skipped (no solution or marked skip), speed x%.1f" % [to_run.size(), cli_results.size(), time_scale_speed])

	if to_run.is_empty():
		_finish_all.call_deferred()
		return
	set_process(true)
	_ensure_game_scene.call_deferred()

func _split_filter(value: String) -> Array[String]:
	var out: Array[String] = []
	for part in value.split(",", false):
		var p := part.strip_edges().to_lower()
		if not p.is_empty():
			out.append(p)
	return out

func _puzzle_has_card_matching(puzzle: Puzzle, filters: Array[String]) -> bool:
	for card_scene in puzzle.get_card_scenes():
		if card_scene == null:
			continue
		var card_key: String = card_scene.resource_path.get_file().get_basename().to_lower().trim_suffix("card")
		if filters.any(func(f): return card_key == f or card_key.contains(f)):
			return true
	return false

func _ensure_game_scene() -> void:
	# The game scene pulls the next puzzle from us in its _ready().
	var current := get_tree().current_scene
	if current == null or current.scene_file_path != GAME_SCENE_PATH:
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _load_next_puzzle_scene() -> void:
	_prepare_next_puzzle()
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE_PATH)

func _prepare_next_puzzle() -> void:
	# URLCapturer reads its URL in _ready(), before Scene asks us for the puzzle,
	# so the override must be in place before the game scene loads.
	var background = $"/root/Background"
	if puzzle_index < filtered_puzzle_paths.size() and _is_url_entry(filtered_puzzle_paths[puzzle_index]):
		var date := _url_date(filtered_puzzle_paths[puzzle_index])
		background.set_url_override("/" + date, url_puzzles[date])
	else:
		background.set_url_override("", "")

func _is_url_entry(entry: String) -> bool:
	return entry.begins_with(URL_ENTRY_PREFIX)

func _url_date(entry: String) -> String:
	return entry.trim_prefix(URL_ENTRY_PREFIX)

func _display_name(entry: String) -> String:
	if _is_url_entry(entry):
		var date := _url_date(entry)
		var enemy := ""
		if url_solutions.has(date):
			enemy = str(url_solutions[date].get("enemy_name", ""))
		elif url_puzzles.has(date):
			enemy = str(url_puzzles[date]).get_slice("enemy_name=", 1).get_slice("&", 0).uri_decode()
		return "%s-%s (URL)" % [date, enemy.replace(" ", "")]
	return entry.get_file().get_basename()

func _load_url_puzzles() -> void:
	if FileAccess.file_exists(URL_PUZZLES_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(URL_PUZZLES_PATH))
		if parsed is Dictionary:
			url_puzzles = parsed
	if FileAccess.file_exists(URL_SOLUTIONS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(URL_SOLUTIONS_PATH))
		if parsed is Dictionary and parsed.get("puzzles") is Dictionary:
			url_solutions = parsed["puzzles"]

func _url_card_keys(search: String) -> Array:
	# "?cards=<base64 of 'lunge-card.PNG,...'>&..." -> ["lunge", ...]
	var encoded := search.get_slice("cards=", 1).get_slice("&", 0).uri_decode()
	var keys: Array = []
	for part in Marshalls.base64_to_utf8(encoded).uri_decode().split(","):
		keys.append(part.strip_edges().to_lower().replace("-card.png", "").replace("-", ""))
	return keys

func _card_scene_for(card_name: String) -> PackedScene:
	var path := "res://Scenes/%sCard.tscn" % card_name.replace(" ", "")
	return load(path) if ResourceLoader.exists(path) else null

func _build_url_steps(date: String) -> Array:
	# Expand {"card", "picks", "effect", "copy"} entries into runner steps.
	var steps: Array = []
	for entry in url_solutions[date].get("steps", []):
		var card_scene := _card_scene_for(str(entry["card"]))
		steps.append({
			"card_scene": card_scene, "card_name": _card_name_of(card_scene, str(entry["card"])),
			"step_type": STEP_TYPE_PLAY, "hand_index": -1, "copy": entry.get("copy", null),
		})
		if entry.has("effect"):
			# A list means several choices from one play, e.g. Echo repeating a Potion.
			var effects: Array = entry["effect"] if entry["effect"] is Array else [entry["effect"]]
			for effect_name in effects:
				steps.append({"step_type": STEP_TYPE_EFFECT, "card_name": str(effect_name), "hand_index": -1})
		if entry.has("picks"):
			if entry["picks"].is_empty():
				steps.append({"step_type": STEP_TYPE_CLOSE_CHOOSER, "card_name": "nothing", "hand_index": -1})
			for pick in entry["picks"]:
				var pick_scene := _card_scene_for(str(pick))
				steps.append({"step_type": STEP_TYPE_PICK_OPEN, "card_name": _card_name_of(pick_scene, str(pick)), "hand_index": -1})
	return steps

func _card_name_of(card_scene: PackedScene, fallback: String) -> String:
	# The in-game name (e.g. "Empty Fist") can differ from the scene file name.
	if card_scene == null:
		return fallback
	var card: Card = card_scene.instantiate()
	var card_name := card.get_card_name()
	card.free()
	return card_name

func _process(_delta: float) -> void:
	# Watchdog: a puzzle that hangs (e.g. awaiting a signal that never fires)
	# is failed so the run keeps going.
	if not cli_mode or active_run_id < 0:
		return
	var elapsed := Time.get_ticks_msec() - puzzle_started_msec
	if elapsed > cli_puzzle_timeout_msec:
		_finish_puzzle(active_run_id, "FAIL", "timed out after %ds during %s" % [elapsed / 1000, current_step_label])

func _resolve_puzzle_cli(card_play_delay_seconds: float) -> void:
	var run_id := next_run_id
	next_run_id += 1
	active_run_id = run_id
	puzzle_started_msec = Time.get_ticks_msec()
	current_step_label = "setup"
	current_notes.clear()
	choice_option_counts.clear()
	choice_labels.clear()
	Engine.set_time_scale(time_scale_speed)

	var scene: Scene = get_tree().current_scene
	var puzzle: Puzzle = scene.get_puzzle()
	# URL puzzles and scene puzzles without a recording use Tests/puzzle_solutions.json.
	var steps: Array = current_url_steps if not current_url_steps.is_empty() or _is_url_entry(current_puzzle_path) \
		else puzzle.get_card_solution_steps()
	var step_count := steps.size()
	open_chooser_picks = 0

	var steps_played := 0
	for i in step_count:
		if not _is_running(run_id, scene) or scene.game_over:
			break
		var step_data: Dictionary = steps[i]
		var target_index: int = int(step_data.get("hand_index", -1))
		var step_type: int = int(step_data.get("step_type", STEP_TYPE_PLAY))
		var card_name: String = str(step_data.get("card_name", ""))
		if card_name.is_empty():
			var card_scene: PackedScene = step_data.get("card_scene", null)
			if card_scene == null:
				_finish_puzzle(run_id, "FAIL", "step %d/%d: solution names a card that doesn't exist" % [i + 1, step_count], i, step_count)
				return
			card_name = _card_name_of(card_scene, "?")
		elif step_type == STEP_TYPE_PLAY and step_data.get("card_scene", null) == null:
			_finish_puzzle(run_id, "FAIL", "step %d/%d: no card scene for '%s'" % [i + 1, step_count, card_name], i, step_count)
			return
		current_step_label = "step %d/%d (%s %s)" % [i + 1, step_count, _step_type_name(step_type), card_name]

		var close_after: bool = not _more_picks_follow(steps, i)
		var failure: String = await _run_step(run_id, scene, step_type, card_name, target_index, close_after, step_data)
		if failure.is_empty():
			steps_played = i + 1
		if not _is_running(run_id, scene):
			break
		if not failure.is_empty():
			_finish_puzzle(run_id, "FAIL", "%s: %s" % [current_step_label, failure], i, step_count)
			return

		await _wait_until_settled(run_id, scene)
		if not _is_running(run_id, scene):
			break
		await get_tree().create_timer(card_play_delay_seconds).timeout

	if active_run_id != run_id:
		return  # watchdog already recorded this puzzle
	if steps_played < step_count:
		current_notes.append("game ended after %d of %d recorded steps" % [steps_played, step_count])
	current_step_label = "waiting for win screen"
	await _await_outcome(run_id, scene, step_count)

func _run_step(run_id: int, scene: Scene, step_type: int, card_name: String, target_index: int, close_after: bool = true, step_data: Dictionary = {}) -> String:
	var hand: Hand = scene.get_node("HandScrollContainer/Hand")
	var cards_choose_area: CardsChooseArea = scene.get_node("CanvasLayer/CardsChooseArea")
	var card_choice_view: CardChoiceView = scene.get_node("CanvasLayer/CardChoiceView")
	var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

	match step_type:
		STEP_TYPE_PICK_OPEN, STEP_TYPE_CLOSE_CHOOSER:
			if not cards_choose_area.visible:
				open_chooser_picks = 0
			await _wait_for_cards_choose_area(cards_choose_area)
			if not _is_running(run_id, scene):
				return ""
			if not cards_choose_area.visible:
				return "card chooser never opened"
			if step_type == STEP_TYPE_CLOSE_CHOOSER:
				_confirm_chooser(cards_choose_area)
				open_chooser_picks = 0
				return ""
			var open_collection: Array = _get_open_chooser_collection(scene, cards_choose_area)
			var picked: Card = _find_card_in_collection(open_collection, card_name, -1)
			if picked == null or not _mark_chosen(cards_choose_area, picked):
				return "%s not offered (options: %s)" % [card_name, _card_names(open_collection)]
			open_chooser_picks += 1
			# Confirm once this chooser's picks are done (e.g. Armory "Choose 2"); the
			# next pick step then waits for the next chooser (e.g. a replayed Armory).
			if close_after or open_chooser_picks >= cards_choose_area.get_max_card_choose_amount():
				_confirm_chooser(cards_choose_area)
				open_chooser_picks = 0
			return ""
		STEP_TYPE_EFFECT:
			var waited_frames := 0
			while not card_choice_view.visible and waited_frames < 120:
				await get_tree().process_frame
				if not _is_running(run_id, scene):
					return ""
				waited_frames += 1
			if not card_choice_view.visible:
				return "effect choice never opened"
			var buttons: Array = card_choice_view.get_node("CardEffectChoicesContainer").get_children() \
				.filter(func(c): return c is CardEffectChoiceButton)
			var options: Array[String] = []
			for button in buttons:
				var effect: CardEffect = button.get_card_effect()
				var description := effect.get_effect_short_description()
				options.append(description)
				var script_name: String = effect.get_script().resource_path.get_file().to_lower() if effect.get_script() else ""
				if description.to_lower().contains(card_name.to_lower()) or script_name.contains(card_name.to_lower()):
					card_choice_view.select_card_effect(effect)
					return ""
			return "no '%s' effect offered (options: %s)" % [card_name, ", ".join(options)]
		STEP_TYPE_CHOOSE_HAND, STEP_TYPE_CHOOSE_DISCARD, STEP_TYPE_CHOOSE_CREATE:
			await _wait_for_cards_choose_area(cards_choose_area)
			if not _is_running(run_id, scene):
				return ""
			if not cards_choose_area.visible:
				return "card chooser never opened"
			var collection: Array = _get_choose_collection(step_type, cards_choose_area, hand, discard_panel)
			var selected: Card = _find_card_in_collection(collection, card_name, target_index)
			if selected == null:
				return "%s not offered (options: %s)" % [card_name, _card_names(collection)]
			_mark_chosen(cards_choose_area, selected)
			if close_after:
				_confirm_chooser(cards_choose_area)
			return ""

	# A prompt the recording has no answer for (e.g. Scrap's discard chooser in
	# an old recording, or any effect choice) is answered from the choice plan.
	await _answer_unrecorded_prompts(run_id, scene)
	if not _is_running(run_id, scene):
		return ""

	# Play step: wait for the card to be in hand and playable.
	var waited := 0.0
	var playable: Card = null
	while waited <= cli_card_wait:
		playable = _pick_playable_copy(card_name, target_index, step_data.get("copy", null))
		if playable != null:
			break
		await get_tree().process_frame
		if not _is_running(run_id, scene):
			return ""
		waited += get_process_delta_time()
	if playable == null:
		var in_hand: Array = hand.get_cards().filter(func(c): return c.get_card_name() == card_name)
		if in_hand.is_empty():
			return "%s not in hand (hand: %s)" % [card_name, _card_names(hand.get_cards())]
		return "%s in hand but not playable (%s)" % [card_name, _describe_play_blockers(scene, in_hand[0])]

	playable.play()
	return ""

func _pick_playable_copy(card_name: String, target_index: int, copy_hint = null) -> Card:
	# copy_hint: true = a (cheaper) Trace copy, false = the original, null = unknown.
	# A recorded hand position wins if it still points at a playable copy.
	var hand: Hand = get_tree().current_scene.get_node("HandScrollContainer/Hand")
	var cards_in_hand: Array = hand.get_cards()
	if target_index >= 0 and target_index < cards_in_hand.size():
		var at_index: Card = cards_in_hand[target_index]
		if at_index != null and at_index.get_card_name() == card_name and at_index.can_play_for_resolver():
			return at_index
	var candidates: Array = cards_in_hand.filter(
		func(c): return c != null and c.get_card_name() == card_name and c.can_play_for_resolver())
	if candidates.size() <= 1:
		return candidates[0] if candidates.size() == 1 else null
	# Copies can differ, e.g. Trace makes a 0-cost copy alongside the original.
	# Group by cost; if they all cost the same, any copy will do.
	candidates.sort_custom(func(a, b): return a.energy_cost < b.energy_cost)
	var distinct: Array = []
	for c in candidates:
		if distinct.is_empty() or distinct[-1].energy_cost != c.energy_cost:
			distinct.append(c)
	if distinct.size() == 1:
		return distinct[0]
	if copy_hint is bool:
		return distinct[0] if copy_hint else distinct[-1]
	# Which copy to play is an unrecorded decision: cheapest first, then search.
	var decision := choice_option_counts.size()
	var pick: int = mini(choice_plan[decision] if decision < choice_plan.size() else 0, distinct.size() - 1)
	choice_option_counts.append(distinct.size())
	choice_labels.append("%s costing %d" % [card_name, distinct[pick].energy_cost])
	return distinct[pick]

func _answer_unrecorded_prompts(run_id: int, scene: Scene) -> void:
	# Each unanswered prompt is a "decision". choice_plan[d] picks the option for
	# decision d (default 0). If the puzzle then fails, _advance_choice_plan()
	# moves to the next combination and the puzzle is replayed.
	var cards_choose_area: CardsChooseArea = scene.get_node("CanvasLayer/CardsChooseArea")
	var card_choice_view: CardChoiceView = scene.get_node("CanvasLayer/CardChoiceView")
	var guard := 0
	while _is_running(run_id, scene) and (cards_choose_area.visible or card_choice_view.visible) and guard < 10:
		guard += 1
		var decision := choice_option_counts.size()
		var pick: int = choice_plan[decision] if decision < choice_plan.size() else 0
		if card_choice_view.visible:
			var buttons: Array = card_choice_view.get_node("CardEffectChoicesContainer").get_children() \
				.filter(func(c): return c is CardEffectChoiceButton)
			if buttons.is_empty():
				return
			pick = mini(pick, buttons.size() - 1)
			choice_option_counts.append(buttons.size())
			var effect: CardEffect = buttons[pick].get_card_effect()
			choice_labels.append("effect '%s'" % effect.get_effect_short_description())
			card_choice_view.select_card_effect(effect)
		else:
			# Options: select nothing, then each single card, then each pair
			# (when the chooser allows 2+), in hand order.
			var collection: Array = _get_open_chooser_collection(scene, cards_choose_area)
			var options: Array = _chooser_selections(collection.size(), cards_choose_area.get_max_card_choose_amount())
			pick = mini(pick, options.size() - 1)
			choice_option_counts.append(options.size())
			var chosen_names: Array[String] = []
			for card_index in options[pick]:
				var chosen: Card = collection[card_index]
				chosen_names.append(chosen.get_card_name())
				_mark_chosen(cards_choose_area, chosen)
			choice_labels.append("chooser: %s" % (" + ".join(chosen_names) if not chosen_names.is_empty() else "nothing"))
			_confirm_chooser(cards_choose_area)
		await _wait_until_settled(run_id, scene)

func _chooser_selections(card_count: int, max_amount: int) -> Array:
	# [[], [0], [1], ..., [0, 1], [0, 2], ...] — sets of card indices to select.
	var options: Array = [[]]
	if max_amount >= 1:
		for i in card_count:
			options.append([i])
	if max_amount >= 2:
		for i in card_count:
			for j in range(i + 1, card_count):
				options.append([i, j])
	return options

func _get_open_chooser_collection(scene: Scene, cards_choose_area: CardsChooseArea) -> Array:
	match cards_choose_area.populate_cards_type:
		CardsChooseArea.PopulateCardsType.FromDiscard:
			return scene.get_node("DiscardPanel").get_cards()
		CardsChooseArea.PopulateCardsType.FromCreate:
			return cards_choose_area.get_card_creator().get_cards()
	return scene.get_node("HandScrollContainer/Hand").get_cards()

func _advance_choice_plan() -> bool:
	# Odometer over the decisions seen in the last attempt, last decision first.
	var plan: Array[int] = choice_plan.duplicate()
	plan.resize(choice_option_counts.size())
	for i in range(choice_option_counts.size() - 1, -1, -1):
		if plan[i] + 1 < choice_option_counts[i]:
			plan[i] += 1
			plan.resize(i + 1)
			choice_plan = plan
			return true
	return false

func _wait_until_settled(run_id: int, scene: Scene) -> void:
	# Wait for the card, buffs and enemy to finish resolving, or for the game to
	# ask the player for input (a card chooser or card-effect choice).
	var enemy: Enemy = scene.get_node("Enemy")
	var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
	var cards_choose_area: CardsChooseArea = scene.get_node("CanvasLayer/CardsChooseArea")
	var card_choice_view: CardChoiceView = scene.get_node("CanvasLayer/CardChoiceView")
	await get_tree().process_frame
	while _is_running(run_id, scene) and not scene.game_over \
			and not cards_choose_area.visible and not card_choice_view.visible \
			and (scene.is_card_resolving() or enemy.is_animating() or buffs_container.is_animating()):
		await get_tree().process_frame

func _await_outcome(run_id: int, scene, step_count: int) -> void:
	# `scene` is untyped: it is already freed if the win screen loaded mid-solution.
	var waited := 0.0
	while active_run_id == run_id:
		var current := get_tree().current_scene
		if current != null and current.name == "EndGameScreen":
			_finish_puzzle(run_id, "PASS", "", step_count, step_count)
			return
		if _is_running(run_id, scene):
			await _answer_unrecorded_prompts(run_id, scene)
		if _is_running(run_id, scene):
			var player: Health = scene.get_node("Health")
			if scene.game_over and player.is_dead():
				_finish_puzzle(run_id, "FAIL", "player died", step_count, step_count)
				return
			if waited > cli_outcome_timeout:
				var enemy: Enemy = scene.get_node("Enemy")
				_finish_puzzle(run_id, "FAIL", "all %d steps played but enemy survived at %d HP" % [step_count, enemy.get_health()], step_count, step_count)
				return
		await get_tree().process_frame
		waited += get_process_delta_time()

func _is_running(run_id: int, scene) -> bool:
	# `scene` is untyped on purpose: it may already be freed (win screen loaded).
	return active_run_id == run_id and is_instance_valid(scene) and not scene.is_queued_for_deletion()

func _finish_puzzle(run_id: int, status: String, reason: String, steps_played: int = 0, step_count: int = 0) -> void:
	if run_id != active_run_id:
		return
	active_run_id = -1
	Engine.set_time_scale(1.0)
	$"/root/Background".clear()

	# Unrecorded choices were made: if this combination failed, try the next one.
	if status == "FAIL" and choice_attempt + 1 < max_choice_attempts and _advance_choice_plan():
		choice_attempt += 1
		puzzle_index -= 1  # replay the same puzzle
		_load_next_puzzle_scene()
		return

	if not choice_labels.is_empty():
		current_notes.append("unrecorded choices made by runner: %s" % ", ".join(_collapse_repeats(choice_labels)))
		if choice_attempt > 0:
			var suffix := ""
			if status != "PASS":
				if choice_attempt + 1 >= max_choice_attempts:
					suffix = " (hit the limit of %d)" % max_choice_attempts
				else:
					suffix = " (all combinations exhausted)"
			current_notes.append("tried %d choice combination(s)%s" % [choice_attempt + 1, suffix])
	var seconds := (Time.get_ticks_msec() - puzzle_started_msec) / 1000.0
	_add_result(current_puzzle_path, status, reason, steps_played, step_count, seconds)
	choice_plan.clear()
	choice_attempt = 0
	if puzzle_index < filtered_puzzle_paths.size():
		_load_next_puzzle_scene()
	else:
		_finish_all.call_deferred()

func _add_result(path: String, status: String, reason: String, steps_played: int, step_count: int, seconds: float = 0.0) -> void:
	cli_results.append({
		"puzzle": _display_name(path),
		"path": path,
		"status": status,
		"reason": reason,
		"steps": step_count,
		"seconds": snappedf(seconds, 0.01),
		"notes": current_notes.duplicate() if status != "SKIP" else [],
	})
	if status == "SKIP":
		return
	var line := "%s  %s" % [status, _display_name(path)]
	if not reason.is_empty():
		line += "  -- " + reason
	print(line)
	for note in current_notes:
		print("      note: " + note)

func _finish_all() -> void:
	set_process(false)
	var counts := {"PASS": 0, "FAIL": 0, "SKIP": 0}
	for r in cli_results:
		counts[r.status] += 1
	print("")
	print("==== PUZZLE TEST SUMMARY ====")
	for r in cli_results:
		if r.status == "FAIL":
			print("FAIL  %s  -- %s" % [r.puzzle, r.reason])
			for note in r.notes:
				print("      note: " + note)
	print("passed %d, failed %d, skipped %d  [%.1fs]" % [counts.PASS, counts.FAIL, counts.SKIP, (Time.get_ticks_msec() - cli_run_started_msec) / 1000.0])

	if not cli_report_path.is_empty():
		var f := FileAccess.open(cli_report_path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({
				"passed": counts.PASS, "failed": counts.FAIL, "skipped": counts.SKIP,
				"results": cli_results,
			}, "\t"))
			f.close()
			print("Report written to %s" % cli_report_path)
		else:
			push_error("Could not write report to %s" % cli_report_path)
	get_tree().quit(1 if counts.FAIL > 0 else 0)

func _describe_play_blockers(scene: Scene, card: Card) -> String:
	# Mirrors the checks in Card.can_play_for_resolver().
	var energy: Energy = scene.get_node("Energy")
	var parts: Array[String] = ["cost %d, energy %d" % [card.energy_cost, energy.get_energy_amount()]]
	if not card.can_pay_cost(card.energy_cost):
		parts.append("can't pay cost")
	var play_area = scene.get_node("CardPlayArea")
	if play_area != null and not play_area.is_useable():
		parts.append("play area not usable")
	if scene.is_card_resolving():
		parts.append("another card still resolving (%d)" % scene.resolving_cards)
	if scene.get_node("Enemy").is_animating():
		parts.append("enemy animating")
	if scene.get_node("BuffsContainer").is_animating():
		parts.append("buffs animating")
	if scene.get_node("CanvasLayer/CardChoiceView").visible:
		parts.append("card choice view open")
	return ", ".join(parts)

func _collapse_repeats(labels: Array[String]) -> Array[String]:
	# ["a", "a", "a", "b"] -> ["a x3", "b"]
	var out: Array[String] = []
	var i := 0
	while i < labels.size():
		var j := i
		while j < labels.size() and labels[j] == labels[i]:
			j += 1
		out.append(labels[i] if j - i == 1 else "%s x%d" % [labels[i], j - i])
		i = j
	return out

func _step_type_name(step_type: int) -> String:
	match step_type:
		STEP_TYPE_CHOOSE_HAND: return "choose-from-hand"
		STEP_TYPE_CHOOSE_DISCARD: return "choose-from-discard"
		STEP_TYPE_CHOOSE_CREATE: return "choose-created"
		STEP_TYPE_PICK_OPEN: return "pick"
		STEP_TYPE_EFFECT: return "effect"
		STEP_TYPE_CLOSE_CHOOSER: return "pick"
	return "play"

func _card_names(cards: Array) -> String:
	var names: Array[String] = []
	for c in cards:
		if c != null and is_instance_valid(c):
			names.append(c.get_card_name())
	return ", ".join(names) if not names.is_empty() else "empty"
