extends Node

@export var cards_root_dir: String = "res://Scenes"
@export var scene_suffix: String = "Card.scn"

func _ready() -> void:
	var card_paths = _collect_card_scene_paths(cards_root_dir)
	if card_paths.is_empty():
		push_warning("No *%s files found under %s" % [scene_suffix, cards_root_dir])
		get_tree().quit()
		return

	card_paths.sort()
	for scene_path in card_paths:
		var description = _get_card_description(scene_path)
		if description == null:
			continue
		print("%s\t%s" % [scene_path, description])

	get_tree().quit()

func _collect_card_scene_paths(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Unable to open directory: %s" % dir_path)
		return paths

	dir.list_dir_begin()
	while true:
		var entry = dir.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue

		var full_path = "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			paths.append_array(_collect_card_scene_paths(full_path))
		elif entry.ends_with(scene_suffix):
			paths.append(full_path)
	dir.list_dir_end()

	return paths

func _get_card_description(scene_path: String) -> String:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_warning("Failed to load scene: %s" % scene_path)
		return ""

	var instance = packed.instantiate()
	if instance == null:
		push_warning("Failed to instantiate: %s" % scene_path)
		return ""

	var description := ""
	if instance.has_method("get_card_description_without_bb_code"):
		description = instance.get_card_description_without_bb_code()
	elif instance.has_method("get_card_description"):
		description = instance.get_card_description()
	elif instance.has_method("get"):
		description = str(instance.get("card_description"))
	else:
		push_warning("%s does not expose a card description getter" % scene_path)

	instance.queue_free()
	return description.strip_edges()
