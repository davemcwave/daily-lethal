extends Node

func _ready() -> void:
	for buff_scene in get_buff_scenes():
		var buff: Buff = load(buff_scene).instantiate()
		var activation_type_names: Array[String] = []
		for activation_type in buff.get_activation_types():
			activation_type_names.append(Buff.ActivationType.keys()[activation_type])
		print("%s | %s" % [buff.get_buff_name(), ", ".join(activation_type_names)])

func get_buff_scenes() -> Array:
	var card_scenes: Array = []
	var dir = DirAccess.open("res://Scenes/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": break
		if file.ends_with("Buff.scn"):
			var scene_path = "res://Scenes/" + file
			#var scene = load(scene_path)
			card_scenes.append(scene_path)
	dir.list_dir_end()
	return card_scenes
