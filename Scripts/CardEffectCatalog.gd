extends Control
class_name CardEffectCatalog

@onready var background: Background = get_node("/root/Background")
var effect_entries: Array = []

func _ready() -> void:
	load_effects()
	for entry in effect_entries:
		print("[%s] (%s) %s" % [entry["name"], entry["node_name"], entry["description"]])

func load_effects() -> void:
	effect_entries.clear()
	for packed_scene: PackedScene in background.get_all_card_effect_scenes():
		var effect: CardEffect = packed_scene.instantiate()
		
		if effect == null or effect.get_effect_name().is_empty():
			continue
		
		effect_entries.append({
			"name": effect.get_effect_name(),
			"description": effect.get_effect_description(),
			"node_name": effect.get_name()
		})
		effect.queue_free()
