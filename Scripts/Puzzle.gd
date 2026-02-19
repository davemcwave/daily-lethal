extends Node
class_name Puzzle

@export_group("Puzzle")
@export var puzzle_date: String = "2025-01-09"
@export_file("*.scn") var previous_puzzle_scene
@export_file("*.scn") var next_puzzle_scene
@export var randomize_cards: bool = false
@export var random_card_count: int = 6
@export_enum("Normal", "Nightmare") var difficulty: String = "Normal"

@export_group("Enemy")
@export var enemy_health: int = 10
@export var enemy_name: String = "Bad Guy"
@export var enemy_icon_texture: Texture2D = null
@export_enum("Player", "Enemy") var enemy_buff_target: String = "Player"

@export var enemy_buffs: Array[Buff]
@export var eye_1_position: Vector2
@export var eye_2_position: Vector2
@export_group("Player")
@export var player_health: int = 3
@export var player_energy: int = 5

@export_group("Cards")
@export var card_scenes: Array[Resource]
@export var card_solution: Array[Resource]
@export var card_solution_resource_name: String = ""

@export var initial_draw_amount: int = -1

@export_group("Dialog")
@export_enum("Player", "Enemy") var dialogue_first: String = "Player"
@export_multiline var dialogue_lines: Array[String]
@export_multiline var enemy_hurt_lines: Array[String]
@export var enemy_hurt_line_chance: float = 0.0
@export_multiline var death_line: String = ""

var test_puzzle: bool = false
var cached_resource_card_solution: Array = []
var cached_resource_card_solution_hand_indices: Array[int] = []
var cached_resource_card_solution_step_types: Array[int] = []
var has_loaded_resource_card_solution: bool = false

const SOLUTION_STEP_TYPE_PLAY := 0
const SOLUTION_STEP_TYPE_CHOOSE_HAND := 1
const SOLUTION_STEP_TYPE_CHOOSE_DISCARD := 2
const SOLUTION_STEP_TYPE_CHOOSE_CREATE := 3

func has_eye_positions() -> bool:
	return eye_1_position != null and eye_2_position != null

func get_eye_positions() -> Array[Vector2]:
	return [eye_1_position, eye_2_position]
	
func get_hurt_line_chance() -> float:
	return enemy_hurt_line_chance
	
func set_test_puzzle(new_test_puzzle: bool) -> void:
	test_puzzle = new_test_puzzle 

func get_enemy_hurt_lines() -> Array[String]:
	return enemy_hurt_lines
	
func get_dialogue_first() -> String:
	return dialogue_first

func is_nightmare_difficulty() -> bool:
	return difficulty == "Nightmare"
	
func get_difficulty() -> String:
	return difficulty
	
func has_any_cards(check_card_scenes: Array) -> bool:
	var cards: Array[Card] = []
	for card_scene in card_scenes:
		cards.append(card_scene.instantiate())
		
	for check_card_scene in check_card_scenes:
		var check_card: Card = check_card_scene.instantiate()
		
		for card: Card in cards:
			if card.get_card_name() == check_card.get_card_name():
				return true
	return false

func has_enemy_abilities() -> bool:
	return get_enemy_abilities().size() > 0

func get_enemy_abilities() -> Array[EnemyAbility]:
	var enemy_abilities: Array[EnemyAbility] = []
	for child in get_children():
		if child is EnemyAbility:
			enemy_abilities.append(child)
	return enemy_abilities
	

func activate_enemy_abilities() -> bool:
	if has_enemy_abilities():
		var all_activated: bool = true
		for enemy_ability: EnemyAbility in get_enemy_abilities():
			var activated: bool = await enemy_ability.activate()
			if not activated:
				all_activated = false
		return all_activated
	else:
		return false
	
func get_dialogue_lines() -> Array[String]:
	return dialogue_lines
	
func is_test_puzzle() -> bool:
	return test_puzzle
	
func do_randomize_cards() -> bool:
	return randomize_cards
	
func get_card_solution() -> Array:
	var resource_solution: Array = get_resource_card_solution()
	if not resource_solution.is_empty():
		return resource_solution
	return card_solution

func get_card_solution_steps() -> Array:
	var solution: Array = get_card_solution()
	var hand_indices: Array[int] = _get_hand_indices_for_size(solution.size())
	var step_types: Array[int] = _get_step_types_for_size(solution.size())
	var steps: Array = []
	for i in range(solution.size()):
		var card_scene = solution[i]
		var hand_index: int = hand_indices[i] if i < hand_indices.size() else -1
		var step_type: int = step_types[i] if i < step_types.size() else SOLUTION_STEP_TYPE_PLAY
		steps.append({
			"card_scene": card_scene,
			"hand_index": hand_index,
			"step_type": step_type
		})
	return steps

func get_resource_card_solution() -> Array:
	if not has_loaded_resource_card_solution:
		cached_resource_card_solution = load_card_solution_from_resource()
		has_loaded_resource_card_solution = true
	return cached_resource_card_solution

func load_card_solution_from_resource() -> Array:
	cached_resource_card_solution_hand_indices.clear()
	cached_resource_card_solution_step_types.clear()
	for candidate_path: String in get_card_solution_resource_paths():
		if candidate_path.is_empty():
			continue
		if not ResourceLoader.exists(candidate_path):
			continue
		var resource = load(candidate_path)
		if resource == null:
			continue
		if resource is CardSolutionResource:
			var resource_hand_indices: Array[int] = resource.get_hand_indices()
			cached_resource_card_solution_hand_indices = resource_hand_indices.duplicate()
			if resource.has_method("get_step_types"):
				var step_types: Array[int] = resource.get_step_types()
				cached_resource_card_solution_step_types = step_types.duplicate()
			return resource.get_card_scenes()
		if resource.has_method("get_card_scenes"):
			if resource.has_method("get_hand_indices"):
				var extra_indices: Array = resource.get_hand_indices()
				if extra_indices is Array:
					cached_resource_card_solution_hand_indices = extra_indices.duplicate()
			if resource.has_method("get_step_types"):
				var extra_types: Array = resource.get_step_types()
				if extra_types is Array:
					cached_resource_card_solution_step_types = extra_types.duplicate()
			return resource.get_card_scenes()
	return []

func _get_hand_indices_for_size(solution_size: int) -> Array[int]:
	var indices: Array[int] = cached_resource_card_solution_hand_indices.duplicate()
	while indices.size() < solution_size:
		indices.append(-1)
	if indices.size() > solution_size:
		indices.resize(solution_size)
	return indices

func _get_step_types_for_size(solution_size: int) -> Array[int]:
	var types: Array[int] = cached_resource_card_solution_step_types.duplicate()
	while types.size() < solution_size:
		types.append(SOLUTION_STEP_TYPE_PLAY)
	if types.size() > solution_size:
		types.resize(solution_size)
	return types

func get_card_solution_resource_paths() -> Array[String]:
	var paths: Array[String] = []
	for slug in get_card_solution_slugs():
		if slug.is_empty():
			continue
		var normalized_slug: String = slug
		if slug.ends_with(".tres"):
			normalized_slug = slug.substr(0, slug.length() - 5)
		paths.append("res://Scenes/Puzzles/Solutions/%s.tres" % normalized_slug)
	return paths

func get_card_solution_slugs() -> Array[String]:
	var slugs: Array[String] = []
	if not card_solution_resource_name.is_empty():
		slugs.append(normalize_solution_slug(card_solution_resource_name))
	if not puzzle_date.is_empty() and not enemy_name.is_empty():
		slugs.append("%s-%s" % [puzzle_date, normalize_solution_slug(enemy_name)])
	if not puzzle_date.is_empty():
		slugs.append(puzzle_date)
	if not scene_file_path.is_empty():
		var file_name: String = scene_file_path.get_file().get_basename()
		if file_name.ends_with("Puzzle"):
			file_name = file_name.substr(0, file_name.length() - "Puzzle".length())
		slugs.append(normalize_solution_slug(file_name))
	return slugs

func normalize_solution_slug(value: String) -> String:
	var lowercase: String = value.strip_edges().to_lower()
	var builder := ""
	for char in lowercase:
		var code: int = char.unicode_at(0)
		var character := char
		if character == "." or character == " " or character == "_" or character == ":":
			character = "-"
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "-":
			builder += character
	return builder

func get_random_card_count() -> int:
	return random_card_count

func get_enemy_buffs() -> Array[Buff]:
	return enemy_buffs

func get_enemy_health() -> int:
	return enemy_health
	
func get_previous_puzzle_scene():
	return previous_puzzle_scene

func get_initial_draw_amount() -> int:
	return initial_draw_amount
	
func set_initial_draw_amount(new_initial_draw_amount: int) -> void:
	initial_draw_amount = new_initial_draw_amount

func get_death_line() -> String:
	return death_line
	
func get_enemy_name() -> String:
	return enemy_name
	
func get_enemy_icon_texture() -> Texture2D:
	return enemy_icon_texture

func get_card_scenes() -> Array[Resource]:
	return card_scenes
	
func clear_card_scenes() -> void:
	card_scenes.clear()

func set_card_scenes(new_card_scenes: Array[Resource]) -> void:
	card_scenes = new_card_scenes
	
func add_card_scene(new_card_scene: Resource) -> void:
	card_scenes.append(new_card_scene)

func get_puzzle_date() -> String:
	return puzzle_date
	
func get_player_health() -> int:
	return player_health
	
func get_player_energy() -> int:
	return player_energy

func get_enemy_buff_target() -> String:
	return enemy_buff_target
	
func get_next_puzzle_scene():
	return next_puzzle_scene
