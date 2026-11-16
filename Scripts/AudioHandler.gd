extends Node

@export var mute_all: bool = false
@onready var original_pitch_scales = {}
@export var mute_sfx = get_children()

## Options > Mute All and the Music / SFX volumes, saved on this device.
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	save_original_pitch_scales()
	_load_audio_settings()

	if not mute_all:
		play_sfx("BGMusic", 1)

func _load_audio_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	mute_all = settings.get_value("audio", "mute_all", mute_all)
	if settings.has_section_key("audio", "music_db") and has_node("BGMusic"):
		$BGMusic.volume_db = settings.get_value("audio", "music_db")
	if settings.has_section_key("audio", "sfx_db"):
		for child in get_children():
			if child is AudioStreamPlayer and child.name != "BGMusic":
				child.volume_db = settings.get_value("audio", "sfx_db")

func save_audio_setting(key: String, value) -> void:
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)  # keep the other settings
	settings.set_value("audio", key, value)
	settings.save(SETTINGS_PATH)

func save_original_pitch_scales() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			var sfx_node: AudioStreamPlayer = child
			original_pitch_scales[sfx_node] = sfx_node.pitch_scale
	
func play_sfx(node_name: String, pitch_scale: float = -1.0, volume_db: float = -999) -> void:
	if mute_all or OS.has_feature("web"):  # the web builds are always silent (the Windows build has sound)
		return
	
	if get_node(node_name) in mute_sfx:
		return
	
	var sfx_node: AudioStreamPlayer = get_node(node_name)
	
	var use_custom_pitch_scale = pitch_scale > -1
	if use_custom_pitch_scale:
		sfx_node.pitch_scale = pitch_scale
		
	if volume_db != -999:
		sfx_node.volume_db = volume_db
		
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
