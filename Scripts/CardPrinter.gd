extends Node
class_name CardPrinter

## Prints all cards and their effects from Scenes/*Card.scn files
## Usage: Add this node to your scene and call print_all_cards() or run in _ready()

@export var print_on_ready: bool = false
@export var cards_directory: String = "res://Scenes/"

func _ready() -> void:
	if print_on_ready:
		print_all_cards()

func print_all_cards() -> void:
	print("\n========== CARD PRINTER ==========\n")

	var card_files = find_all_card_files()

	if card_files.is_empty():
		print("No card files found in %s" % cards_directory)
		return

	print("Found %d card files:\n" % card_files.size())

	for card_path in card_files:
		print_card_info(card_path)

	print("\n========== END CARD PRINTER ==========\n")

func find_all_card_files() -> Array[String]:
	var card_files: Array[String] = []
	var dir = DirAccess.open(cards_directory)

	if dir == null:
		push_error("Failed to open directory: %s" % cards_directory)
		return card_files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Match files that end with "Card.scn"
		if not dir.current_is_dir() and file_name.ends_with("Card.scn"):
			card_files.append(cards_directory + file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	card_files.sort()
	return card_files

func print_card_info(card_path: String) -> void:
	# Load and instantiate the card
	var card_scene = load(card_path)
	if card_scene == null:
		print("%s - ERROR: Failed to load" % card_path.get_file())
		return

	var card = card_scene.instantiate()
	if card == null:
		print("%s - ERROR: Failed to instantiate" % card_path.get_file())
		return

	# Get card name
	var card_name = "Unknown"
	if card.has_method("get_card_name"):
		card_name = card.get_card_name()
	elif "card_name" in card:
		card_name = card.card_name

	# Get card effects
	var effects = []
	if card.has_method("get_card_effects"):
		effects = card.get_card_effects()
	elif "card_effects" in card:
		effects = card.card_effects

	# Build effect names list
	var effect_names = []
	for effect in effects:
		var effect_name = effect.get_class()
		if effect.has_method("get_effect_name"):
			effect_name = effect.get_effect_name()
		elif "effect_name" in effect:
			effect_name = effect.effect_name
		effect_names.append(effect_name)

	# Print simple format: CardName - Effect1, Effect2, Effect3
	if effect_names.is_empty():
		print("%s - No effects" % card_name)
	else:
		print("%s - %s" % [card_name, ", ".join(effect_names)])

	# Clean up
	card.queue_free()
