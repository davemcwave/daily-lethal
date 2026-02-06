extends Panel
class_name DialogPanel

@onready var dialog_text: RichTextLabel = $DialogText
@onready var audio_handler = get_node("/root/AudioHandler")
@export var dialog_sfx_index = 0
var force_dialog_finish: bool = false
var playing: bool = false
func _ready():
	$NextIcon/Timer.connect("timeout", blink_next_icon)
	$NextIcon.hide()
	
	dialog_text.set_text("")
	#if visible:
		#play_dialog_text()

func _input(event):
	if event.is_action_pressed("skip_dialog") and playing: 
		force_dialog_finish = true

func set_icon_texture(new_icon_texture: Texture2D) -> void:
	$CharacterIcon.set_texture(new_icon_texture)
	
func set_title_text(new_title_text: String) -> void:
	$TitleText.set_text(new_title_text)

func blink_next_icon() -> void:
	$NextIcon.set_visible(not $NextIcon.visible)
	
func enable_blink_next_icon(enabled: bool) -> void:
	if enabled:
		$NextIcon/Timer.start()
		$NextIcon.show()
	else:
		$NextIcon/Timer.stop()
		$NextIcon.hide()

func set_dialog_sfx_index(new_dialog_sfx_index: int) -> void:
	dialog_sfx_index = new_dialog_sfx_index
	
func play_dialog_text(optional_text: String = "") -> bool:
	if not optional_text.is_empty():
		dialog_text.set_text(optional_text)
		
	playing = true
	dialog_text.visible_characters = 0
	while dialog_text.visible_ratio < 1.0:
		$DialogText.visible_characters += 1
		
		if $DialogText.visible_characters % 3 == 0:
			audio_handler.play_sfx("Dialog%dSFX" % dialog_sfx_index, randf_range(0.5, 0.7))
	
		if force_dialog_finish:
			dialog_text.visible_characters = -1
			force_dialog_finish = false
			break
			
		await get_tree().create_timer(0.02).timeout
	
	playing = false
	return true
	
