extends Node

@export var mute_all: bool = false
@onready var original_pitch_scales = {}
@export var mute_sfx = get_children()

func _ready() -> void:
	save_original_pitch_scales()
	
	#play_sfx("BGMusic")

func save_original_pitch_scales() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			var sfx_node: AudioStreamPlayer = child
			original_pitch_scales[sfx_node] = sfx_node.pitch_scale
	
func play_sfx(node_name: String, pitch_scale: float = -1.0) -> void:
	if mute_all:
		return
	
	if get_node(node_name) in mute_sfx:
		return
	
	var sfx_node: AudioStreamPlayer = get_node(node_name)
	
	var use_custom_pitch_scale = pitch_scale > -1
	if use_custom_pitch_scale:
		sfx_node.pitch_scale = pitch_scale
		
	sfx_node.play()
	
	#if use_custom_pitch_scale:
		#await get_tree().create_timer(0.1).timeout
		#sfx_node.pitch_scale = original_pitch_scales[sfx_node]

func reset_pitch_scale(node_name: String) -> void:
	var sfx_node: AudioStreamPlayer = get_node(node_name)
	sfx_node.pitch_scale = original_pitch_scales[sfx_node]
	
func stop_sfx(node_name: String) -> void:
	var sfx_node: AudioStreamPlayer = get_node(node_name)
	sfx_node.stop()

func increase_pitch_scale(node_name: String, increase: float) -> void:
	var sfx_node: AudioStreamPlayer = get_node(node_name)
	sfx_node.pitch_scale += increase
	
func play_random_dialog_sfx() -> void:
	var dialog_sfxs = []
	for child in get_children():
		if "Dialog" in child.name:
			dialog_sfxs.append(child)
			
	var dialog_sfx: AudioStreamPlayer = dialog_sfxs[randi() % dialog_sfxs.size()]
	play_sfx(dialog_sfx.name)
