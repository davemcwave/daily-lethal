extends Node2D

enum Difficulty { VERY_EASY, EASY, MEDIUM, HARD, VERY_HARD }

const DIFFICULTY_COLORS := {
	Difficulty.VERY_EASY: Color(0.53, 0.81, 0.92, 1.0),  # Light Blue
	Difficulty.EASY: Color(0.56, 0.93, 0.56, 1.0),       # Light Green
	Difficulty.MEDIUM: Color(1.0, 0.84, 0.0, 1.0),       # Gold/Yellow
	Difficulty.HARD: Color(1.0, 0.65, 0.0, 1.0),         # Orange
	Difficulty.VERY_HARD: Color(1.0, 0.39, 0.28, 1.0),   # Red/Tomato
}

const ENEMY_DIFFICULTIES := {
	"Robot": Difficulty.VERY_EASY,
	"Mantis Shrimp": Difficulty.VERY_EASY,
	"Sea Monster": Difficulty.EASY,
	"Bloodthorn": Difficulty.EASY,
	"Skeleton": Difficulty.EASY,
	"Dr Bonez": Difficulty.EASY,
	"Giant Rat": Difficulty.EASY,
	"Creeping Vine": Difficulty.EASY,
	"Decrepit Mouse": Difficulty.EASY,
	"Origami": Difficulty.EASY,
	"Dust Droid": Difficulty.EASY,
	"Beetle": Difficulty.EASY,
	"Snowman": Difficulty.EASY,
	"Mushroom": Difficulty.EASY,
	"Bandit": Difficulty.EASY,
	"Radiant Slug": Difficulty.EASY,
	"Scorpion": Difficulty.EASY,
	"Viper": Difficulty.EASY,
	"Ninja": Difficulty.EASY,
	"Werewolf": Difficulty.MEDIUM,
	"Goblin": Difficulty.MEDIUM,
	"Kobold": Difficulty.MEDIUM,
	"Mimic": Difficulty.MEDIUM,
	"Cloaker": Difficulty.MEDIUM,
	"Genie": Difficulty.MEDIUM,
	"Mummy": Difficulty.MEDIUM,
	"Animated Armor": Difficulty.MEDIUM,
	"Ooze": Difficulty.MEDIUM,
	"Stirge": Difficulty.MEDIUM,
	"Rock Golem": Difficulty.MEDIUM,
	"Weaver": Difficulty.MEDIUM,
	"Vampire": Difficulty.MEDIUM,
	"Earth Elemental": Difficulty.MEDIUM,
	"Hell Hound": Difficulty.MEDIUM,
	"Earthworm": Difficulty.MEDIUM,
	"Mad Scientist": Difficulty.MEDIUM,
	"Beholder": Difficulty.MEDIUM,
	"Yeti": Difficulty.MEDIUM,
	"Displacer Beast": Difficulty.MEDIUM,
	"Lightning Elemental": Difficulty.MEDIUM,
	"Gravedigger": Difficulty.MEDIUM,
	"Tentacled Cultist": Difficulty.MEDIUM,
	"Scarecrow": Difficulty.MEDIUM,
	"Flumph": Difficulty.MEDIUM,
	"Void Monster": Difficulty.MEDIUM,
	"Deity": Difficulty.MEDIUM,
	"Moocher": Difficulty.MEDIUM,
	"Redeye": Difficulty.MEDIUM,
	"Firebug": Difficulty.MEDIUM,
	"Chupacabra": Difficulty.MEDIUM,
	"Artificer": Difficulty.MEDIUM,
	"Giftman": Difficulty.MEDIUM,
	"Porcupine": Difficulty.MEDIUM,
	"Cherub": Difficulty.MEDIUM,
	"Pinky": Difficulty.MEDIUM,
	"Water Drake": Difficulty.MEDIUM,
	"Charger": Difficulty.MEDIUM,
	"Leprechaun": Difficulty.MEDIUM,
	"Car Battery": Difficulty.MEDIUM,
	"Raven": Difficulty.MEDIUM,
	"Demon Nurse": Difficulty.MEDIUM,
	"Ghost Pirate": Difficulty.MEDIUM,
	"Delvers": Difficulty.MEDIUM,
	"Target Dummy": Difficulty.MEDIUM,
	"Hydra": Difficulty.MEDIUM,
	"Dr. Frankenstein": Difficulty.MEDIUM,
	"Frankenstein's Monster": Difficulty.MEDIUM,
	"Fungi": Difficulty.MEDIUM,
	"Termites": Difficulty.MEDIUM,
	"Living Shadow": Difficulty.MEDIUM,
	"Addition Sign": Difficulty.MEDIUM,
	"Black Knight": Difficulty.MEDIUM,
	"Vending Machine": Difficulty.MEDIUM,
	"Ancient Tree": Difficulty.MEDIUM,
	"Weather Witch": Difficulty.MEDIUM,
	"Elder": Difficulty.MEDIUM,
	"Modron": Difficulty.MEDIUM,
	"Butler": Difficulty.MEDIUM,
	"Axebeak": Difficulty.MEDIUM,
	"Warrior": Difficulty.MEDIUM,
	"Evil Carrot": Difficulty.MEDIUM,
	"Wolverine": Difficulty.MEDIUM,
	"Carnivorous Plant": Difficulty.MEDIUM,
	"Leech": Difficulty.HARD,
	"Ogre": Difficulty.HARD,
	"Troll": Difficulty.HARD,
	"Cyclops": Difficulty.HARD,
	"Sapling": Difficulty.HARD,
	"Soldier": Difficulty.HARD,
	"Crawler": Difficulty.HARD,
	"Snipe Bird": Difficulty.HARD,
	"Tentacle Pirate": Difficulty.HARD,
	"Thunderbird": Difficulty.HARD,
	"Noggle": Difficulty.HARD,
	"Collector": Difficulty.HARD,
	"Demogorgon": Difficulty.HARD,
	"Funambulist": Difficulty.HARD,
	"Gargoyle": Difficulty.HARD,
	"Alchemist": Difficulty.HARD,
	"Merfolk": Difficulty.HARD,
	"Witch": Difficulty.HARD,
	"Roc": Difficulty.HARD,
	"Assassin": Difficulty.HARD,
	"Dire Wolf": Difficulty.HARD,
	"Warlock": Difficulty.HARD,
	"Wasp Swarm": Difficulty.HARD,
	"Giant Wurm": Difficulty.HARD,
	"Lich": Difficulty.HARD,
	"Poltergeist": Difficulty.HARD,
	"Buzzsaw Droid": Difficulty.HARD,
	"Red Dragon": Difficulty.HARD,
	"Barbarian": Difficulty.HARD,
	"Fiend": Difficulty.HARD,
	"Spark Golem": Difficulty.HARD,
	"Pterosaur": Difficulty.HARD,
	"Time Lord": Difficulty.HARD,
	"Grave Robber": Difficulty.HARD,
	"Pink Slime": Difficulty.HARD,
	"Flail Snail": Difficulty.HARD,
	"Serpents": Difficulty.HARD,
	"Ice Golem": Difficulty.HARD,
	"Fairy": Difficulty.HARD,
	"Giant Bat": Difficulty.HARD,
	"Blue Dragon": Difficulty.HARD,
	"Bigfoot": Difficulty.HARD,
	"Rat King": Difficulty.HARD,
	"Giant Eel": Difficulty.HARD,
	"Pufferfish": Difficulty.HARD,
	"Dwarven Miner": Difficulty.HARD,
	"Speed Elf": Difficulty.HARD,
	"Wraith": Difficulty.HARD,
	"Giant Crab": Difficulty.HARD,
	"Green Dragon": Difficulty.HARD,
	"Harpy": Difficulty.HARD,
	"Hammerhead": Difficulty.HARD,
	"Gelatinous Cube": Difficulty.VERY_HARD,
	"Kraken": Difficulty.VERY_HARD,
	"Minotaur": Difficulty.VERY_HARD,
	"Flame Imp": Difficulty.VERY_HARD,
	"Naga": Difficulty.VERY_HARD,
	"Flame Giant": Difficulty.VERY_HARD,
	"Mana Imp": Difficulty.VERY_HARD,
	"Shoggoth": Difficulty.VERY_HARD,
	"Time Demon": Difficulty.VERY_HARD,
	"Zombie": Difficulty.VERY_HARD,
	"Cannoneer": Difficulty.VERY_HARD,
	"Cursed Campfire": Difficulty.VERY_HARD,
	"Monk": Difficulty.VERY_HARD,
	"Titan": Difficulty.VERY_HARD,
	"Owlbear": Difficulty.VERY_HARD,
	"Paladin": Difficulty.VERY_HARD,
}

func _ready() -> void:
	load_story_progress()

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""
var enemy_texture: Texture2D = null
var puzzle_date: String = ""
var puzzle_scene: String = ""
var next_puzzle_scene = null
var from_story_view: bool = false
var completed_story_puzzles: Array[String] = []
var last_completed_story_puzzle: String = ""
var recorded_card_scene_paths: Array[String] = []
var recorded_card_hand_indices: Array[int] = []
var card_solution_slugs: Array[String] = []
@export var show_tutorial: bool = true

func set_show_tutorial(new_show_tutorial: bool) -> void:
	show_tutorial = new_show_tutorial
	
func get_show_tutorial() -> bool:
	return show_tutorial

func get_difficulty_for_enemy(enemy_name: String) -> int:
	if ENEMY_DIFFICULTIES.has(enemy_name):
		return ENEMY_DIFFICULTIES[enemy_name]
	return Difficulty.MEDIUM  # Default to medium if not found

func get_difficulty_color_for_enemy(enemy_name: String) -> Color:
	var difficulty := get_difficulty_for_enemy(enemy_name)
	return DIFFICULTY_COLORS[difficulty]

func clear() -> void:
	attempts = 0
	best_card_count = 0
	clear_recorded_card_solutions()
	card_solution_slugs.clear()
	from_story_view = false
	
func set_puzzle_scene(new_puzzle_scene: String) -> void:
	puzzle_scene = new_puzzle_scene

func set_next_puzzle_scene(new_next_puzzle_scene) -> void:
	next_puzzle_scene = new_next_puzzle_scene

func get_next_puzzle_scene():
	return next_puzzle_scene
	
func get_puzzle_scene() -> String:
	return puzzle_scene

func set_from_story_view(value: bool) -> void:
	from_story_view = value

func is_from_story_view() -> bool:
	return from_story_view

func mark_story_puzzle_completed(puzzle_scene_path: String) -> void:
	if puzzle_scene_path.is_empty():
		return
	last_completed_story_puzzle = puzzle_scene_path
	if puzzle_scene_path not in completed_story_puzzles:
		completed_story_puzzles.append(puzzle_scene_path)
		save_story_progress()

func get_last_completed_story_puzzle() -> String:
	return last_completed_story_puzzle

func clear_last_completed_story_puzzle() -> void:
	last_completed_story_puzzle = ""

func is_story_puzzle_completed(puzzle_scene_path: String) -> bool:
	return puzzle_scene_path in completed_story_puzzles

func get_completed_story_puzzles() -> Array[String]:
	return completed_story_puzzles.duplicate()

func save_story_progress() -> void:
	var save_path := "user://story_progress.save"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return
	var data := {"completed_puzzles": completed_story_puzzles}
	file.store_string(JSON.stringify(data))
	file.close()

func load_story_progress() -> void:
	var save_path := "user://story_progress.save"
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return
	var data = json.get_data()
	if data is Dictionary and data.has("completed_puzzles"):
		completed_story_puzzles.clear()
		for puzzle_path in data["completed_puzzles"]:
			completed_story_puzzles.append(puzzle_path)

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
