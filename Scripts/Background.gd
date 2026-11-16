extends Node2D

enum Difficulty { VERY_EASY, EASY, MEDIUM, HARD, VERY_HARD }

const DIFFICULTY_COLORS := {
	Difficulty.VERY_EASY: Color.PINK,  # Light Blue
	Difficulty.EASY: Color.GREEN,       # Light Green
	Difficulty.MEDIUM: Color.YELLOW,       # Gold/Yellow
	Difficulty.HARD: Color.RED,         # Orange
	Difficulty.VERY_HARD: Color.PURPLE,   # Red/Tomato
}

const PUZZLE_AUTHORS := {
	"Evil Robot": "mcwavegames",
	"Sea Monster": "mcwavegames",
	"Bloodthorn": "mcwavegames",
	"Skeleton": "mcwavegames",
	"Dr Bonez": "mcwavegames",
	"Werewolf": "mcwavegames",
	"Leech": "mcwavegames",
	"Gelatinous Cube": "mcwavegames",
	"Kraken": "mcwavegames",
	"Goblin": "mcwavegames",
	"Minotaur": "mcwavegames",
	"Ogre": "mcwavegames",
	"Flame Imp": "mcwavegames",
	"Kobold": "mcwavegames",
	"Giant Rat": "mcwavegames",
	"Mimic": "mcwavegames",
	"Naga": "mcwavegames",
	"Troll": "mcwavegames",
	"Cloaker": "mcwavegames",
	"Cyclops": "mcwavegames",
	"Genie": "mcwavegames",
	"Mummy": "mcwavegames",
	"Animated Armor": "GamesDeconstructed",
	"Sapling": "laminatedmoth",
	"Soldier": "Aquacier",
	"Flame Giant": "jatloe",
	"Ooze": "mcwavegames",
	"Stirge": "mcwavegames",
	"Rock Golem": "laminatedmoth",
	"Weaver": "mcwavegames",
	"Vampire": "Penguiny5110",
	"Creeping Vine": "mcwavegames",
	"Earth Elemental": "Sandcastle",
	"Hell Hound": "Penguiny5110",
	"Earthworm": "Erik",
	"Mad Scientist": "ZeeBee",
	"Crawler": "Sandcastle",
	"Beholder": "Penguiny5110",
	"Yeti": "mcwavegames",
	"Snipe Bird": "ZeeBee",
	"Tentacle Pirate": "Lunerias",
	"Displacer Beast": "Penguiny5110",
	"Lightning Elemental": "OnOff",
	"Thunderbird": "Lejcles",
	"Gravedigger": "OnOff",
	"Noggle": "Samuel",
	"Mana Imp": "Cochonouille",
	"Collector": "ZeeBee",
	"Demogorgon": "David abt",
	"Decrepit Mouse": "Macropolo",
	"Origami": "Macropolo",
	"Dust Droid": "ZeeBee",
	"Funambulist": "jatloe",
	"Tentacled Cultist": "Palestar",
	"Gargoyle": "Sacred",
	"Alchemist": "BenMiff",
	"Merfolk": "Sandcastle",
	"Scarecrow": "BenMiff",
	"Witch": "deltarail",
	"Roc": "BenMiff",
	"Beetle": "Sacred",
	"Assassin": "BenMiff",
	"Dire Wolf": "BenMiff",
	"Flumph": "Penguiny5110",
	"Warlock": "BenMiff",
	"Snowman": "OnOff",
	"Wasp Swarm": "BenMiff",
	"Giant Wurm": "BenMiff & Moribam",
	"Void Creature": "OnOff",
	"Deity": "OnOff",
	"Moocher": "ZeeBee",
	"Redeye": "ZeeBee",
	"Firebug": "ZeeBee",
	"Lich": "OnOff",
	"Poltergeist": "BenMiff",
	"Chupacabra": "BenMiff",
	"Artificer": "BenMiff",
	"Buzzsaw Droid": "BenMiff",
	"Red Dragon": "BenMiff",
	"Barbarian": "ZeeBee",
	"Giftman": "ZeeBee",
	"Porcupine": "ZeeBee",
	"Fiend": "Versze",
	"Spark Golem": "Penguiny5110",
	"Shoggoth": "BenMiff & Sandcastle",
	"Cherub": "Yungha",
	"Pinky": "ZeeBee",
	"Water Drake": "Versze",
	"Pterosaur": "BenMiff",
	"Time Lord": "BenMiff",
	"Charger": "Andyroid22",
	"Grave Robber": "RadioInactive",
	"Pink Slime": "BenMiff",
	"Flail Snail": "Moribam",
	"Time Demon": "jatloe",
	"Serpents": "potatomato",
	"Ice Golem": "BenMiff",
	"Fairy": "RadioInactive",
	"Giant Bat": "BenMiff",
	"Zombie": "RadioInactive",
	"Leprechaun": "RadioInactive",
	"Car Battery": "potatomato",
	"Raven": "BenMiff",
	"Blue Dragon": "BenMiff",
	"Bigfoot": "Moribam",
	"Demon Nurse": "BenMiff",
	"Ghost Pirate": "Penguiny5110",
	"Delvers": "potatomato",
	"Rat King": "RoboTea",
	"Cannoneer": "RadioInactive",
	"Target Dummy": "RoboTea",
	"Hydra": "BenMiff",
	"Giant Eel": "RadioInactive",
	"Pufferfish": "potatomato",
	"Cursed Campfire": "vroenVen",
	"Mantis Shrimp": "Penguiny5110",
	"Dr. Frankenstein": "RadioInactive",
	"Frankenstein's Monster": "RadioInactive",
	"Dwarven Miner": "BenMiff",
	"Monk": "RadioInactive",
	"Mushroom": "BenMiff",
	"Fungi": "RoboTea",
	"Termites": "BenMiff",
	"Speed Elf": "potatomato",
	"Titan": "RadioInactive",
	"Bandit": "BenMiff",
	"Living Shadow": "BenMiff",
	"Addition Sign": "jatloe",
	"Wraith": "RoboTea",
	"Owlbear": "BenMiff",
	"Radiant Slug": "potatomato",
	"Black Knight": "BenMiff",
	"Vending Machine": "RadioInactive",
	"Giant Crab": "BenMiff",
	"Paladin": "RoboTea",
	"Ancient Tree": "RoboTea",
	"Weather Witch": "BenMiff",
	"Elder": "Penguiny5110",
	"Green Dragon": "RadioInactive",
	"Scorpion": "RoboTea",
	"Modron": "potatomato",
	"Butler": "BenMiff",
	"Axebeak": "potatomato",
	"Harpy": "RadioInactive",
	"Viper": "BenMiff",
	"Warrior": "RadioInactive",
	"Ninja": "BenMiff",
	"Evil Carrot": "potatomato",
	"Hammerhead": "potatomato",
	"Wolverine": "BenMiff",
	"Carnivorous Plant": "RadioInactive",
	"Wight": "BenMiff",
	"Jack Frost": "Vanillabean",
	"Crusader": "KirbyCarrot",
	"Worg": "Deloptin",
	"Gunslinger": "Gold_me",
	"Cockatrice": "Kookoo",
	"Punching Bag": "kino",
	"Blacksmith": "BenMiff",
	"Moon Elemental": "Vanillabean",
	"Swordmaster": "ARMA",
	"Banshee": "RadioInactive",
	"Circuit Breaker": "potatomato",
	"Mad Hatter": "BenMiff"
}

const ENEMY_DIFFICULTIES := {
	"Evil Robot": Difficulty.VERY_EASY,
	"Mantis Shrimp": Difficulty.VERY_EASY,
	"Sea Monster": Difficulty.VERY_EASY,
	"Bloodthorn": Difficulty.VERY_EASY,
	"Skeleton": Difficulty.VERY_EASY,
	"Dr Bonez": Difficulty.VERY_EASY,
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
	"Werewolf": Difficulty.EASY,
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
	"Elder": Difficulty.HARD,
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
	"Kraken": Difficulty.HARD,
	"Minotaur": Difficulty.HARD,
	"Flame Imp": Difficulty.VERY_HARD,
	"Naga": Difficulty.VERY_HARD,
	"Flame Giant": Difficulty.VERY_HARD,
	"Mana Imp": Difficulty.VERY_HARD,
	"Shoggoth": Difficulty.VERY_HARD,
	"Time Demon": Difficulty.VERY_HARD,
	"Zombie": Difficulty.VERY_HARD,
	"Cannoneer": Difficulty.HARD,
	"Cursed Campfire": Difficulty.VERY_HARD,
	"Monk": Difficulty.VERY_HARD,
	"Titan": Difficulty.VERY_HARD,
	"Owlbear": Difficulty.VERY_HARD,
	"Paladin": Difficulty.VERY_HARD,
}

## Options saved on this device (user://settings.cfg).
const SETTINGS_PATH := "user://settings.cfg"
## Options > Show damage math: the math beside an attack held over the play area.
## On by default; players can turn it off.
var show_damage_math: bool = true

func set_show_damage_math(on: bool) -> void:
	show_damage_math = on
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)  # keep any other settings
	settings.set_value("display", "show_damage_math", on)
	settings.save(SETTINGS_PATH)

## Whether this player has been shown the tutorial (Play shows it first if not).
var tutorial_seen: bool = false

func set_tutorial_seen() -> void:
	tutorial_seen = true
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)  # keep any other settings
	settings.set_value("progress", "tutorial_seen", true)
	settings.save(SETTINGS_PATH)

func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		show_damage_math = settings.get_value("display", "show_damage_math", true)
		tutorial_seen = settings.get_value("progress", "tutorial_seen", false)
	if "--show-damage-math" in OS.get_cmdline_user_args():
		show_damage_math = true  # dev: on for this run only, not saved

func _ready() -> void:
	_load_settings()
	load_story_progress()
	load_archive_progress()
	_apply_puzzle_cmdline_arg()
	_open_card_lab_from_url()
	_schedule_screenshot()

## Card Builder (Scenes/Builder/CardBuilder.tscn): the card being built survives
## a "Try it" trip to a test puzzle; a "Back to Card Lab" button stays on top of
## the puzzle (and its win/lose screens) until pressed.
const CARD_BUILDER_SCENE := "res://Scenes/Builder/CardBuilder.tscn"
const GAME_SCENE := "res://Scenes/Scene0Desktop.tscn"
var card_builder_definition: Dictionary = {}
## All the Card Lab's custom cards (card_builder_definition is the one open).
var card_builder_cards: Array = []
var card_builder_current: int = 0
## The builder's "Try it" settings (HP, energy, enemy HP, copies, other cards).
var card_builder_try_settings: Dictionary = {}
var card_builder_trying: bool = false
## Custom card definitions the Library sent to edit (Edit in Card Lab); the Card Lab adds them.
var card_lab_incoming: Array = []
## A Library puzzle sent to the Puzzle Lab (Edit in Puzzle Lab): ShareCode.decode()'s Lab shape.
var card_lab_incoming_puzzle: Dictionary = {}
## A note for the Library to show once (e.g. after importing a share code).
var library_notice: String = ""
## A share code from the page's address (playlethal.fun/library?import=...): the Library opens
## its Import box with it.
var library_import_code: String = ""
var _builder_back_layer: CanvasLayer = null

## True only in a browser whose only pointer is a touch screen (phones, tablets,
## iPads, which say they're a Mac). Touch laptops have a fine pointer too.
const _TOUCH_ONLY_JS := "matchMedia('(pointer: coarse)').matches && !matchMedia('(any-pointer: fine)').matches"

## The Card Lab is laid out for a wide screen with a mouse (drag to reorder,
## right-click, hover). Off in the mobile web build and on phones and tablets;
## card-lab/index.html makes the same check before opening the game.
func card_lab_available() -> bool:
	if OS.has_feature("web_build") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return false
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		return not bool(JavaScriptBridge.eval(_TOUCH_ONLY_JS, true))
	return true

## The web pages open the desktop web build at a screen instead of a puzzle:
## playlethal.fun/puzzle-lab -> ?puzzle_lab=1 (the old /card-lab's ?card_lab=1 too) opens
## the Puzzle Lab (where it's available: it needs a mouse); /library -> ?library=1 opens
## the Library.
func _open_card_lab_from_url() -> void:
	if not OS.has_feature("web"):
		return
	var search = JavaScriptBridge.eval("window.location.search", true)
	if not search is String:
		return
	var flags := {}
	for pair in str(search).trim_prefix("?").split("&", false):
		flags[pair.split("=")[0]] = pair.split("=", true, 1)[1].uri_decode() if "=" in pair else ""
	if (flags.has("puzzle_lab") or flags.has("card_lab")) and card_lab_available():
		get_tree().change_scene_to_file.call_deferred(CARD_BUILDER_SCENE)
	elif flags.has("library") or flags.has("import"):
		library_import_code = str(flags.get("import", ""))
		get_tree().change_scene_to_file.call_deferred(ARCHIVE_SCENE)

## The web build's way back to the site (it has no main menu): its home page.
func open_site_home() -> void:
	JavaScriptBridge.eval("window.location.href = '/';", true)

## Opens a test puzzle (a "?cards=..." query) from the Card Builder.
func start_card_builder_try(search: String) -> void:
	set_url_override("/", search)
	card_builder_trying = true
	_show_builder_back_button()
	get_tree().change_scene_to_file(GAME_SCENE)

func return_to_card_builder() -> void:
	card_builder_trying = false
	set_url_override("", "")
	clear()
	if _builder_back_layer != null:
		_builder_back_layer.queue_free()
		_builder_back_layer = null
	get_tree().change_scene_to_file(CARD_BUILDER_SCENE)

func _show_builder_back_button() -> void:
	if _builder_back_layer != null:
		return
	# A child of this autoload, so it survives the scene changes during the puzzle.
	_builder_back_layer = CanvasLayer.new()
	_builder_back_layer.layer = 100
	add_child(_builder_back_layer)
	var button := Button.new()
	button.text = "‹  Back to Puzzle Lab"
	button.add_theme_font_override("font", load("res://Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf"))
	button.add_theme_font_size_override("font_size", 13)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#18181b") if state != "hover" else Color("#3f3f46")
		box.border_color = Color("#3f3f46")
		box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color("#fafafa"))
	# Top right, below the puzzle's banner (and the win screen's Archive button).
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_right = -12
	button.offset_top = 64
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.pressed.connect(return_to_card_builder)
	_builder_back_layer.add_child(button)

## Dev helper: --screenshot=<path.png> saves the screen after loading, then quits.
func _schedule_screenshot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			var path := arg.trim_prefix("--screenshot=")
			var frames := 90
			for other in OS.get_cmdline_user_args():
				if other.begins_with("--screenshot-frames="):  # wait longer, e.g. for the deal
					frames = maxi(1, other.trim_prefix("--screenshot-frames=").to_int())
			for i in frames:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(path)
			print("Saved screenshot to " + path)
			get_tree().quit()

## Off the web there is no window.location, so URL puzzles ("?cards=...") are
## fed in here instead; URLCapturer reads these when JavaScriptBridge has nothing.
var url_override_path: String = ""
var url_override_search: String = ""
const URL_PUZZLES_FILE := "res://custom-redirects.json"

func set_url_override(path: String, search: String) -> void:
	url_override_path = path
	url_override_search = search

## Looks up a URL puzzle by date in custom-redirects.json. Returns "" if missing.
func get_url_puzzle_search(date: String) -> String:
	if not FileAccess.file_exists(URL_PUZZLES_FILE):
		return ""
	var redirects = JSON.parse_string(FileAccess.get_file_as_string(URL_PUZZLES_FILE))
	if redirects is Dictionary and redirects.has(date):
		return str(redirects[date])
	return ""

## Dev helpers:
##   godot --path . -- --puzzle=demogorgon   first scene puzzle whose file name contains the text
##   godot --path . -- --url=2026-03-10      URL puzzle for that date (from custom-redirects.json)
##   godot --path . -- "--url=?cards=..."    a creator test puzzle, as opened by /submit-puzzle
func _apply_puzzle_cmdline_arg() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--url="):
			var date := arg.trim_prefix("--url=")
			if date.begins_with("?"):
				# A raw "?cards=..." query, like the submit page's Test Puzzle button opens.
				set_url_override("/", date)
				print("Starting on creator test puzzle: " + date.left(60))
				return
			var search := get_url_puzzle_search(date)
			if search.is_empty():
				push_warning("No URL puzzle for --url=%s" % date)
			else:
				set_url_override("/" + date, search)
				print("Starting on URL puzzle: " + date)
			return
		if not arg.begins_with("--puzzle="):
			continue
		var query := arg.trim_prefix("--puzzle=").to_lower()
		for file in DirAccess.get_files_at("res://Scenes/Puzzles/"):
			if file.ends_with(".tscn") and file.to_lower().contains(query):
				set_puzzle_scene("res://Scenes/Puzzles/" + file)
				print("Starting on puzzle: " + file)
				return
		push_warning("No puzzle matches --puzzle=%s" % query)

var attempts = 0
var best_card_count: int = 0
var enemy_name: String = ""
var enemy_texture: Texture2D = null
var puzzle_date: String = ""
var puzzle_scene: String = ""
var puzzle_is_test: bool = false
var next_puzzle_scene = null
var from_story_view: bool = false
var completed_story_puzzles: Array[String] = []
var last_completed_story_puzzle: String = ""
var recorded_card_scene_paths: Array[String] = []
var recorded_card_hand_indices: Array[int] = []
var recorded_card_step_types: Array[int] = []
var recorded_card_instance_ids: Array[int] = []
## The same playthrough as structured steps (card, picks, effect choices).
var recorded_solution_steps: Array = []

const SOLUTION_STEP_TYPE_PLAY := 0
const SOLUTION_STEP_TYPE_CHOOSE_HAND := 1
const SOLUTION_STEP_TYPE_CHOOSE_DISCARD := 2
const SOLUTION_STEP_TYPE_CHOOSE_CREATE := 3
var card_solution_slugs: Array[String] = []
var using_desktop_layout: bool = false
@export var show_tutorial: bool = true

func set_show_tutorial(new_show_tutorial: bool) -> void:
	show_tutorial = new_show_tutorial
	
func get_show_tutorial() -> bool:
	return show_tutorial

func set_using_desktop_layout(is_desktop_layout: bool) -> void:
	using_desktop_layout = is_desktop_layout

func is_using_desktop_layout() -> bool:
	return using_desktop_layout

func get_difficulty_for_enemy(enemy_name: String) -> int:
	if ENEMY_DIFFICULTIES.has(enemy_name):
		return ENEMY_DIFFICULTIES[enemy_name]
	return Difficulty.MEDIUM  # Default to medium if not found

func get_difficulty_color_for_enemy(enemy_name: String) -> Color:
	var difficulty := get_difficulty_for_enemy(enemy_name)
	return DIFFICULTY_COLORS[difficulty]

func get_author_for_enemy(enemy_name: String) -> String:
	if PUZZLE_AUTHORS.has(enemy_name):
		return PUZZLE_AUTHORS[enemy_name]
	return ""

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

func set_from_story_view(value: bool) -> void:
	from_story_view = value

func is_from_story_view() -> bool:
	return from_story_view

func is_web_platform() -> bool:
	return Engine.has_singleton("JavaScriptBridge") and OS.has_feature("web")

func mark_story_puzzle_completed(puzzle_scene_path: String) -> void:
	if puzzle_scene_path.is_empty():
		return
	last_completed_story_puzzle = puzzle_scene_path
	last_completed_story_puzzle_was_new = puzzle_scene_path not in completed_story_puzzles
	if last_completed_story_puzzle_was_new:
		completed_story_puzzles.append(puzzle_scene_path)
		save_story_progress()

## True if the last story win was the first time that puzzle was beaten (a replay
## doesn't replay the story map's "world complete" sequence).
var last_completed_story_puzzle_was_new: bool = false

func was_last_story_win_new() -> bool:
	return last_completed_story_puzzle_was_new

func get_last_completed_story_puzzle() -> String:
	return last_completed_story_puzzle

func clear_last_completed_story_puzzle() -> void:
	last_completed_story_puzzle = ""

func is_story_puzzle_completed(puzzle_scene_path: String) -> bool:
	return puzzle_scene_path in completed_story_puzzles

func get_completed_story_puzzles() -> Array[String]:
	return completed_story_puzzles.duplicate()

## The story puzzle being played (its id in Data/story_worlds.json: a scene path,
## "url:<date>" or "story:<name>"), or "" outside story mode.
var story_puzzle_id: String = ""
var story_puzzle_entry: Dictionary = {}

func get_story_puzzle_id() -> String:
	return story_puzzle_id

func is_playing_story_puzzle() -> bool:
	return not story_puzzle_id.is_empty()

## The story puzzle's "dialog" from Data/story_worlds.json ({} if it has none):
## {"first": "Enemy"|"Player", "lines": [...], "death": "..."} (hurt lines are off).
func get_story_dialog() -> Dictionary:
	var dialog = story_puzzle_entry.get("dialog", {})
	return dialog if dialog is Dictionary else {}

## Starts a story puzzle from its Data/story_worlds.json entry. Scene puzzles load
## their scene; the others are "?cards=..." queries, fed in like a --url= puzzle.
func start_story_puzzle(entry: Dictionary) -> void:
	story_puzzle_id = str(entry.get("id", ""))
	story_puzzle_entry = entry
	from_archive = false
	set_from_story_view(true)
	set_show_tutorial(false)
	clear()
	if entry.has("scene"):
		set_url_override("", "")
		set_puzzle_scene(str(entry["scene"]))
	else:
		# A released puzzle keeps its date (so it also counts as played in the archive).
		var path := "/" + str(entry["date"]) if entry.has("date") else "/story"
		set_url_override(path, str(entry.get("search", "")))
		set_puzzle_scene("")
	get_tree().change_scene_to_file(GAME_SCENE)

## ---- Puzzle Archive (desktop): every released daily puzzle, from Data/puzzle_archive.json.
const ARCHIVE_SCENE := "res://Scenes/ArchiveView.tscn"
const ARCHIVE_PROGRESS_PATH := "user://archive_progress.save"
var from_archive: bool = false
var archive_puzzle_id: String = ""
var completed_archive_puzzles: Array[String] = []
## Cards ticked in the archive's card filter when it opens (the Cards screen's "Puzzles with this card").
var archive_preset_cards: Array = []
## The archive's current (filtered, sorted) list, so the win screen's NEXT PUZZLE plays the next one.
var archive_queue: Array = []

func get_archive_next_entry() -> Dictionary:
	for i in archive_queue.size():
		if str(archive_queue[i].get("id", "")) == archive_puzzle_id:
			return archive_queue[i + 1] if i + 1 < archive_queue.size() else {}
	return {}

func is_from_archive() -> bool:
	return from_archive

## Plays an archive entry ({"id": "daily:<date>", "date", "scene" or "search"}).
func start_archive_puzzle(entry: Dictionary) -> void:
	leave_story_puzzle()
	set_from_story_view(false)
	set_show_tutorial(false)
	from_archive = true
	archive_puzzle_id = str(entry.get("id", ""))
	clear()
	if entry.has("scene"):
		set_url_override("", "")
		set_puzzle_scene(str(entry["scene"]))
	else:
		# A custom puzzle has no date: it plays like the Card Lab's test puzzle.
		set_url_override("/" + ("" if entry.get("custom", false) else str(entry.get("date", ""))), str(entry.get("search", "")))
		set_puzzle_scene("")
	get_tree().change_scene_to_file(GAME_SCENE)

## Back in the archive (or the main menu): forget the puzzle that was played.
func leave_archive_puzzle() -> void:
	from_archive = false
	archive_puzzle_id = ""
	if not card_builder_trying:
		set_url_override("", "")

func mark_archive_puzzle_completed() -> void:
	if archive_puzzle_id.is_empty() or archive_puzzle_id in completed_archive_puzzles:
		return
	completed_archive_puzzles.append(archive_puzzle_id)
	var file := FileAccess.open(ARCHIVE_PROGRESS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"completed": completed_archive_puzzles}))

func is_archive_puzzle_completed(id: String) -> bool:
	return id in completed_archive_puzzles

func load_archive_progress() -> void:
	if not FileAccess.file_exists(ARCHIVE_PROGRESS_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVE_PROGRESS_PATH))
	if data is Dictionary and data.get("completed") is Array:
		completed_archive_puzzles.clear()
		for id in data["completed"]:
			completed_archive_puzzles.append(str(id))

## Back on the story map (or the main menu): forget the puzzle that was played.
func leave_story_puzzle() -> void:
	story_puzzle_id = ""
	story_puzzle_entry = {}
	if not card_builder_trying:
		set_url_override("", "")

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
			# Saves made before scenes were converted to text store ".scn" paths.
			var migrated_path: String = puzzle_path
			# The old story map stored its buttons' "uid://..." puzzle references.
			if migrated_path.begins_with("uid://"):
				var uid := ResourceUID.text_to_id(migrated_path)
				if uid != ResourceUID.INVALID_ID and ResourceUID.has_id(uid):
					migrated_path = ResourceUID.get_id_path(uid)
			if migrated_path.ends_with(".scn"):
				migrated_path = migrated_path.get_basename() + ".tscn"
			if migrated_path not in completed_story_puzzles:
				completed_story_puzzles.append(migrated_path)

func set_puzzle_date(new_puzzle_date: String) -> void:
	puzzle_date = new_puzzle_date
	
func get_puzzle_date() -> String:
	return puzzle_date

var puzzle_is_creator_test: bool = false

func set_is_test_puzzle(is_test: bool) -> void:
	puzzle_is_test = is_test

func is_test_puzzle() -> bool:
	return puzzle_is_test
	
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
func record_played_card_scene_path(card_scene_path: String, hand_index: int = -1, card_instance_id: int = -1) -> void:
	if card_scene_path.is_empty():
		return
	recorded_card_scene_paths.append(card_scene_path)
	recorded_card_hand_indices.append(hand_index)
	recorded_card_step_types.append(SOLUTION_STEP_TYPE_PLAY)
	recorded_card_instance_ids.append(card_instance_id)

## Called by Card.begin_play_resolution() at the start of every card play.
func record_solution_play(card_scene_path: String) -> void:
	if card_scene_path.is_empty():
		return
	recorded_solution_steps.append({"card": _solution_card_key(card_scene_path)})

func record_cards_choose_selection(card_scene_path: String, source_index: int, step_type: int) -> void:
	if card_scene_path.is_empty():
		return
	recorded_card_scene_paths.append(card_scene_path)
	recorded_card_hand_indices.append(source_index)
	recorded_card_step_types.append(step_type)
	recorded_card_instance_ids.append(-1)
	# A pick belongs to the card that opened the chooser (the last card played).
	if not recorded_solution_steps.is_empty():
		var step: Dictionary = recorded_solution_steps[-1]
		if not step.has("picks"):
			step["picks"] = []
		step["picks"].append(_solution_card_key(card_scene_path))

## Called when a card chooser is confirmed, so "picked nothing" is recorded as [].
func record_chooser_answered() -> void:
	if not recorded_solution_steps.is_empty() and not recorded_solution_steps[-1].has("picks"):
		recorded_solution_steps[-1]["picks"] = []

## Called by CardChoiceView when the player picks one of a card's effects
## (e.g. Potion: heal or damage).
func record_effect_choice(card_effect: CardEffect) -> void:
	if card_effect == null or recorded_solution_steps.is_empty():
		return
	var effect_key := card_effect.get_effect_short_description()
	var script: Script = card_effect.get_script()
	if script != null:
		# "res://Scripts/HealCardEffect.gd" -> "heal"
		effect_key = script.resource_path.get_file().get_basename().to_lower().trim_suffix("cardeffect")
	var step: Dictionary = recorded_solution_steps[-1]
	if not step.has("effect"):
		step["effect"] = []
	step["effect"].append(effect_key)

func clear_recorded_card_solutions() -> void:
	recorded_card_scene_paths.clear()
	recorded_card_hand_indices.clear()
	recorded_card_step_types.clear()
	recorded_card_instance_ids.clear()
	recorded_solution_steps.clear()

## The winning playthrough as steps in Tests/puzzle_solutions.json format:
## [{"card": "Armory", "picks": ["Slash", "Cleave"]}, {"card": "Potion", "effect": "damage"}, ...]
func get_recorded_solution_steps() -> Array:
	var steps: Array = []
	for step: Dictionary in recorded_solution_steps:
		var copy := step.duplicate(true)
		if copy.has("effect") and copy["effect"].size() == 1:
			copy["effect"] = copy["effect"][0]
		steps.append(copy)
	return steps

## Human-readable version, e.g. "Potion (Damage), Armory (Slash, Cleave), Slash".
func get_recorded_solution_text() -> String:
	var parts: Array[String] = []
	for step: Dictionary in recorded_solution_steps:
		var choices: Array[String] = []
		if step.has("picks"):
			choices.append(", ".join(step["picks"]) if not step["picks"].is_empty() else "nothing")
		for effect_key in step.get("effect", []):
			choices.append(str(effect_key).capitalize())
		var text: String = step["card"]
		if not choices.is_empty():
			text += " (%s)" % ", ".join(choices)
		parts.append(text)
	return ", ".join(parts)

func _solution_card_key(card_scene_path: String) -> String:
	# "res://Scenes/EmptyfistCard.tscn" -> "Emptyfist" (matches the scene file).
	return card_scene_path.get_file().get_basename().trim_suffix("Card")

const TEST_SOLUTION_STORAGE_KEY := "lethal_test_solution"

## True when a creator is testing a puzzle they built on /submit-puzzle: a
## "?cards=" puzzle with no date in the URL path (set by Scene.set_puzzle).
## Daily URL puzzles (/2026-03-10?cards=...) have one.
func is_creator_test_puzzle() -> bool:
	return puzzle_is_creator_test

func set_is_creator_test_puzzle(value: bool) -> void:
	puzzle_is_creator_test = value
	if value:
		print("Creator test puzzle: the winning solution will be sent to the submit page.")

## Called on the win screen. For a test puzzle (one built on /submit-puzzle and
## opened with "Test"), hands the winning solution to the submit page through
## localStorage so the creator never has to type it.
func publish_test_puzzle_solution() -> void:
	if not is_test_puzzle() or recorded_solution_steps.is_empty():
		return
	var payload := {
		"search": "",
		"steps": get_recorded_solution_steps(),
		"text": get_recorded_solution_text(),
		"saved_at": Time.get_unix_time_from_system(),
	}
	if not is_web_platform():
		print("Captured test-puzzle solution: " + payload["text"])
		print("Captured test-puzzle steps: " + JSON.stringify(payload["steps"]))
		return
	if not is_creator_test_puzzle():
		return  # a daily URL puzzle, not someone testing a puzzle they built
	var search = JavaScriptBridge.eval("window.location.search")
	payload["search"] = str(search) if search != null else ""
	# JSON.stringify twice: the outer one makes a safe JS string literal.
	JavaScriptBridge.eval("localStorage.setItem('%s', %s);" % [TEST_SOLUTION_STORAGE_KEY, JSON.stringify(JSON.stringify(payload))], true)

func set_card_solution_slugs(new_slugs: Array[String]) -> void:
	card_solution_slugs = new_slugs.duplicate()

func save_played_cards_solution() -> void:
	if recorded_card_scene_paths.is_empty():
		return
	# URL puzzles ("?cards=") run on a placeholder scene puzzle, so the slugs
	# point at that placeholder's solution file; their solutions live in
	# Tests/puzzle_solutions.json instead.
	if is_test_puzzle():
		return
	# Don't overwrite recorded solutions while the resolver is replaying them.
	var puzzle_resolver = get_node_or_null("/root/PuzzleResolver")
	if puzzle_resolver != null and puzzle_resolver.is_active():
		return
	# Opt-in: a dev run only records a win when started with --record-solution
	# (godot --path . -- --puzzle=roc --record-solution). Otherwise playing a puzzle
	# to try it would overwrite its reference solution.
	if not "--record-solution" in OS.get_cmdline_user_args():
		return
	var resource_path: String = get_solution_resource_path()
	if resource_path.is_empty():
		return
	var card_solution_resource := CardSolutionResource.new()
	var packed_scenes: Array[PackedScene] = []
	var filtered_hand_indices: Array[int] = []
	var filtered_step_types: Array[int] = []
	for i in range(recorded_card_scene_paths.size()):
		var scene_path: String = recorded_card_scene_paths[i]
		var hand_index: int = recorded_card_hand_indices[i] if recorded_card_hand_indices.size() > i else -1
		var step_type: int = recorded_card_step_types[i] if recorded_card_step_types.size() > i else SOLUTION_STEP_TYPE_PLAY
		if scene_path.is_empty():
			continue
		if not ResourceLoader.exists(scene_path):
			continue
		var packed_scene = load(scene_path)
		if packed_scene is PackedScene:
			packed_scenes.append(packed_scene)
			filtered_hand_indices.append(hand_index)
			filtered_step_types.append(step_type)
	if packed_scenes.is_empty():
		return
	card_solution_resource.card_scenes = packed_scenes
	card_solution_resource.hand_indices = filtered_hand_indices
	card_solution_resource.step_types = filtered_step_types
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
			if file_name.ends_with("Buff.tscn") and not dir.current_is_dir() and file_name != "Card.tscn":
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
			if file_name.ends_with("CardEffect.tscn") and not dir.current_is_dir() and file_name != "Card.tscn":
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
			if file_name.ends_with("Card.tscn") and not dir.current_is_dir():
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
