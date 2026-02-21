extends Node
class_name CardMetadataExporter

@export_dir var cards_root_dir: String = "res://Scenes"
@export_file("*.json") var output_path: String = "res://card-metadata.json"

func _ready() -> void:
	var metadata: Array = _collect_card_metadata()
	if metadata.is_empty():
		push_warning("No card metadata collected. Check cards_root_dir.")
	else:
		print("Collected metadata for %d cards." % metadata.size())
	_write_metadata(metadata)
	print("Card metadata written to %s" % output_path)
	get_tree().quit()

func _collect_card_metadata() -> Array:
	var results: Array = []
	var dir := DirAccess.open(cards_root_dir)
	if dir == null:
		push_error("Unable to open directory: %s" % cards_root_dir)
		return results

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with("Card.scn"):
			var scene_path := "%s/%s" % [cards_root_dir, entry]
			var packed_scene: PackedScene = load(scene_path)
			if packed_scene:
				var instance = packed_scene.instantiate()
				if instance is Card:
					var card_data := {
						"file": scene_path,
						"name": instance.card_name,
						"energy": instance.energy_cost,
						"color": _color_to_hex(instance.get_background_color())
					}
					results.append(card_data)
				instance.queue_free()
		entry = dir.get_next()
	dir.list_dir_end()
	return results

func _color_to_hex(color: Color) -> String:
	var r = clamp(int(round(color.r * 255.0)), 0, 255)
	var g = clamp(int(round(color.g * 255.0)), 0, 255)
	var b = clamp(int(round(color.b * 255.0)), 0, 255)
	return "#%02x%02x%02x" % [r, g, b]

func _write_metadata(metadata: Array) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write metadata to %s" % output_path)
		return
	var json := JSON.stringify(metadata, "\t")
	file.store_string(json)
