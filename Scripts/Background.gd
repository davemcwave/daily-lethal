extends Node2D

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""
var enemy_texture: Texture2D = null
var puzzle_date: String = ""
var puzzle_scene: String = ""
var next_puzzle_scene = null

func clear() -> void:
	attempts = 0
	best_card_count = 0
	
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
	
func get_card_effect_by_name(card_effect_name: String) -> CardEffect:
	var card_effect_scenes: Array[Resource] = get_all_card_effect_scenes()
	
	for card_effect_scene: Resource in card_effect_scenes:
		var card_effect = card_effect_scene.instantiate()
		if card_effect is CardEffect and card_effect.get_effect_name() == card_effect_name:
			return card_effect
	
	return null
