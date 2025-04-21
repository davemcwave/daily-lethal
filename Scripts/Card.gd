extends Panel
class_name Card

var grabbed: bool = false
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var card_play_area = scene.get_node("CardPlayArea")
@export var card_effect: CardEffect = null
@export var card_name: String = "Slash"
@export var card_description: String = "Deal 2 damage"
@onready var enemy = scene.get_node("Enemy")
@onready var card_preview = scene.get_node("CanvasLayer/CardPreview")
var grab_position = Vector2.ZERO

func _on_gui_input(event):
	if (event.is_action_pressed("select") or event is InputEventScreenTouch) and event.is_pressed():
		grab()
	elif (event.is_action_released("select") or event is InputEventScreenTouch) and not event.is_pressed():
		drop()

func grab() -> void:
	grabbed = true
	grab_position = position
	card_preview.hide()
	#move_to_front()
	
func drop() -> void:
	grabbed = false
	
	if card_play_area != null and card_play_area.has_card() and card_play_area.get_card() == self:
		play()
	else:
		set_position(grab_position)
		
		#if get_parent() is Hand:
			#get_parent().reset_view()

func play():
	if card_effect != null:
		card_effect.apply()
	
	queue_free()
	
func _process(delta):
	if grabbed:
		global_position = get_global_mouse_position() - size/2

func _on_mouse_entered():
	card_preview.show()
	card_preview.set_title(card_name)
	card_preview.set_description(card_description)
	card_preview.set_icon_texture($IconPanel/Icon.get_texture())


func _on_mouse_exited():
	card_preview.hide()
