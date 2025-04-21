extends Panel
class_name Card

const PLAY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]PLAY CARD![/pulse][/b][/center]"
const LOW_ENERGY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]LOW ENERGY[/pulse][/b][/center]"

var grabbed: bool = false
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var card_play_area = scene.get_node("CardPlayArea")
@export var card_effect: CardEffect = null
@export var card_name: String = "Slash"
@export var energy_cost: int = 1
@export var card_description: String = "Deal 2 damage"
@onready var enemy = scene.get_node("Enemy")
@onready var card_preview = scene.get_node("CanvasLayer/CardPreview")
@onready var energy = scene.get_node("Energy")
@onready var play_text = scene.get_node("PlayText")
@onready var background = get_node("/root/Background")
var grab_position = Vector2.ZERO

func _ready():
	$DamageCardEffect.set_target(enemy)
	$EnergyPanel/Energy.set_text("[center]%d[/center]" % energy_cost)
	
func _on_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			grab()
		else:
			drop()
	elif event.is_action_pressed("select"):
		grab()
	elif event.is_action_released("select"):
		drop()

	#elif event is InputEventScreenDrag and card_preview.visible and background.is_mobile():
		#card_preview.hide()
		
func grab() -> void:
	grabbed = true
	grab_position = position
	
	if background.is_web():
		card_preview.hide()
	elif background.is_mobile():
		card_preview.show()
	
	if energy.has_enough_energy(energy_cost):
		play_text.set_text(PLAY_CARD_TEXT)
	else:
		play_text.set_text(LOW_ENERGY_CARD_TEXT)
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
	if energy.has_enough_energy(energy_cost):
		energy.use_energy(energy_cost)
		card_effect.apply()
		scene.increment_card_count()
		queue_free()
	else:
		set_position(grab_position)
		
	scene.check_game_over()
	
func _process(delta):
	if grabbed:
		global_position = get_global_mouse_position() - size/2

func get_energy_cost() -> int:
	return energy_cost
	
func _on_mouse_entered():
	if background.is_web():
		card_preview.show()
		card_preview.set_title(card_name)
		card_preview.set_description(card_description)
		card_preview.set_icon_texture($IconPanel/Icon.get_texture())


func _on_mouse_exited():
	card_preview.hide()
