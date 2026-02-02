extends Node2D

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""
var enemy_texture: Texture2D = null
var puzzle_date: String = ""
var puzzle_scene: String = ""
var next_puzzle_scene = null
var recorded_card_scene_paths: Array[String] = []
var recorded_card_hand_indices: Array[int] = []
var card_solution_slugs: Array[String] = []

func clear() -> void:
	attempts = 0
	best_card_count = 0
	clear_recorded_card_solutions()
	card_solution_slugs.clear()
	
func set_puzzle_scene(new_puzzle_scene: String) -> void:
	puzzle_scene = new_puzzle_scene

func set_next_puzzle_scene(new_next_puzzle_scene) -> void:
	next_puzzle_scene = new_next_puzzle_scene

func get_next_puzzle_scene():
	return next_puzzle_scene
	
func get_puzzle_scene() -> String:
	return puzzle_scene

func set_puzzle_date(new_puzzle_date: String) -> void:
	puzzle_date = new_puzzle_date
	
func get_puzzle_date() -> String:
	return puzzle_date
	
func set_enemy_texture(new_enemy_texture: Texture2D) -> void:
	enemy_texture = new_enemy_texture
	
func get_enemy_texture() -> Texture2D:
	return enemy_texture
	
func add_attempt() -> void:
	attempts += 1
	
func set_best_card_count(new_best_card_count: int) -> void:
	best_card_count = new_best_card_count
	
func set_enemy_name(new_enemy_name: String) -> void:
	enemy_name = new_enemy_name
func record_played_card_scene_path(card_scene_path: String, hand_index: int = -1) -> void:
	if card_scene_path.is_empty():
		return
	recorded_card_scene_paths.append(card_scene_path)
	recorded_card_hand_indices.append(hand_index)

func clear_recorded_card_solutions() -> void:
	recorded_card_scene_paths.clear()
	recorded_card_hand_indices.clear()

func set_card_solution_slugs(new_slugs: Array[String]) -> void:
	card_solution_slugs = new_slugs.duplicate()

func save_played_cards_solution() -> void:
	if recorded_card_scene_paths.is_empty():
		return
	var resource_path: String = get_solution_resource_path()
	if resource_path.is_empty():
		return
	var card_solution_resource := CardSolutionResource.new()
	var packed_scenes: Array[PackedScene] = []
	var filtered_hand_indices: Array[int] = []
	for i in range(recorded_card_scene_paths.size()):
		var scene_path: String = recorded_card_scene_paths[i]
		var hand_index: int = recorded_card_hand_indices[i] if recorded_card_hand_indices.size() > i else -1
		if scene_path.is_empty():
			continue
		if not ResourceLoader.exists(scene_path):
			continue
		var packed_scene = load(scene_path)
		if packed_scene is PackedScene:
			packed_scenes.append(packed_scene)
			filtered_hand_indices.append(hand_index)
	if packed_scenes.is_empty():
		return
	card_solution_resource.card_scenes = packed_scenes
	card_solution_resource.hand_indices = filtered_hand_indices
	ensure_directory_exists(resource_path.get_base_dir())
	var result = ResourceSaver.save(card_solution_resource, resource_path)
	if result != OK:
		push_error("Failed to save card solution to %s (error %d)" % [resource_path, result])

func get_solution_resource_path() -> String:
	for slug in card_solution_slugs:
		var normalized_slug: String = slug
		if normalized_slug.is_empty():
			continue
		if normalized_slug.ends_with(".tres"):
			normalized_slug = normalized_slug.substr(0, normalized_slug.length() - 5)
		return "res://Scenes/Puzzles/Solutions/%s.tres" % normalized_slug
	return ""

func ensure_directory_exists(dir_path: String) -> void:
	if dir_path.is_empty():
		return
	var dir = DirAccess.open(dir_path)
	if dir == null:
		var absolute_path: String = ProjectSettings.globalize_path(dir_path)
		DirAccess.make_dir_recursive_absolute(absolute_path)
	
func cards_are_playing() -> bool:
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.is_playing():
			return true
	return false
	
func mark_puzzle_completed(puzzle_date: String):
	var js_code := """
		(function() {
			const key = 'lethal_completed_puzzles';
			const date = '%s';
			const stored = localStorage.getItem(key);
			const current = stored ? new Set(JSON.parse(stored)) : new Set();
			current.add(date);
			localStorage.setItem(key, JSON.stringify([...current]));
		})();
	""" % puzzle_date
	JavaScriptBridge.eval(js_code, true)
	
func get_all_buff_scenes() -> Array[Resource]:
	var buff_scenes: Array[Resource] = []
	var dir = DirAccess.open("res://Scenes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("Buff.scn") and not dir.current_is_dir() and file_name != "Card.scn":
				var scene_path = "res://Scenes/" + file_name
				var packed_scene = load(scene_path)
				buff_scenes.append(packed_scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	return buff_scenes
	
func get_all_card_effect_scenes() -> Array[Resource]:
	var scenes: Array[Resource] = []
	var dir = DirAccess.open("res://Scenes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("CardEffect.scn") and not dir.current_is_dir() and file_name != "Card.scn":
				var scene_path = "res://Scenes/" + file_name
				var packed_scene = load(scene_path)
				scenes.append(packed_scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	return scenes
	

func get_all_card_scenes() -> Array[Resource]:
	var scenes: Array[Resource] = []
	var dir = DirAccess.open("res://Scenes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("Card.scn") and not dir.current_is_dir():
				var scene_path = "res://Scenes/" + file_name
				var packed_scene = load(scene_path)
				scenes.append(packed_scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	return scenes
	
func get_card_effect_by_name(card_effect_name: String) -> CardEffect:
	var card_effect_scenes: Array[Resource] = get_all_card_effect_scenes()
	
	for card_effect_scene: Resource in card_effect_scenes:
		var card_effect = card_effect_scene.instantiate()
		if card_effect is CardEffect and card_effect.get_effect_name() == card_effect_name:
			return card_effect
	
	return null
