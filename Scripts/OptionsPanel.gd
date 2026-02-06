extends Control

@onready var audio_handler = $"/root/AudioHandler"
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicContainer/MusicSlider
@onready var music_value_label: Label = $Panel/VBoxContainer/MusicContainer/MusicValueLabel
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXContainer/SFXSlider
@onready var sfx_value_label: Label = $Panel/VBoxContainer/SFXContainer/SFXValueLabel
@onready var mute_checkbox: CheckBox = $Panel/VBoxContainer/MuteContainer/MuteCheckBox
@onready var sfx_timer: Timer = $Panel/VBoxContainer/SFXContainer/SFXSlider/Timer
signal closed

var can_sfx_slider_make_noise: bool = true

func _ready() -> void:
	# Initialize values from AudioHandler
	var bg_music = audio_handler.get_node_or_null("BGMusic")
	if bg_music:
		music_slider.value = bg_music.volume_db
		music_value_label.text = str(int(bg_music.volume_db)) + " dB"

	var hit_sfx = audio_handler.get_node_or_null("HitSFX")
	if hit_sfx:
		sfx_slider.value = hit_sfx.volume_db
		sfx_value_label.text = str(int(hit_sfx.volume_db)) + " dB"

	mute_checkbox.button_pressed = audio_handler.mute_all

func _on_music_slider_value_changed(value: float) -> void:
	var bg_music = audio_handler.get_node_or_null("BGMusic")
	if bg_music:
		bg_music.volume_db = value
	music_value_label.text = str(int(value)) + " dB"

func _on_sfx_slider_value_changed(value: float) -> void:
	for child in audio_handler.get_children():
		if child is AudioStreamPlayer and child.name != "BGMusic":
			child.volume_db = value
	sfx_value_label.text = str(int(value)) + " dB"
	if can_sfx_slider_make_noise:
		can_sfx_slider_make_noise = false
		audio_handler.play_sfx("HitSFX")
		
		if sfx_timer.is_stopped():
			sfx_timer.start()

func _on_mute_check_box_toggled(toggled: bool) -> void:
	audio_handler.mute_all = toggled
	if toggled:
		audio_handler.stop_sfx("BGMusic")
	else:
		audio_handler.play_sfx("BGMusic", 1)

func _on_close_button_pressed() -> void:
	closed.emit()
	queue_free()

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
		queue_free()


func _on_sfx_timer_timeout():
	can_sfx_slider_make_noise = true


func _on_delete_save_file_button_pressed():
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to delete your story progress?\n\nThis cannot be undone."
	confirm_dialog.ok_button_text = "Delete"
	confirm_dialog.cancel_button_text = "Cancel"
	confirm_dialog.confirmed.connect(_on_delete_confirmed)
	confirm_dialog.canceled.connect(func(): confirm_dialog.queue_free())
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	var save_path := "user://story_progress.save"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	# Clear the in-memory progress too
	var background = $"/root/Background"
	if background.has_method("load_story_progress"):
		background.completed_story_puzzles.clear()
		background.last_completed_story_puzzle = ""
