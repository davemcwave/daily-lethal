extends Panel
class_name Card

signal played

const PLAY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]PLAY CARD![/pulse][/b][/center]"
const LOW_ENERGY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]LOW ENERGY[/pulse][/b][/center]"

var grabbed: bool = false
@onready var scene = get_tree().get_root().get_node("Scene")
@onready var card_play_area = scene.get_node("CardPlayArea")
@export var card_effects: Array[CardEffect] = []
@export var card_name: String = "Slash"
@export var energy_cost: int = 1
@export var card_description: String = "Deal 2 damage"
@export var remember_last_card_effects: bool = true
@onready var enemy = scene.get_node("Enemy")
@onready var card_preview = scene.get_node("CanvasLayer/CardPreview")
@onready var energy = scene.get_node("Energy")
@onready var play_text = scene.get_node("PlayText")
@onready var background = get_node("/root/Background")
#@onready var last_cards_played_container: GridContainer = scene.get_node("LastCardsPlayedContainer")
@onready var original_z_index = z_index
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var discard_pile_view = scene.get_node("CanvasLayer/DiscardPileView")
var grab_position = Vector2.ZERO
var grabbed_timestamp = null
var last_mouse_position = null
var playing: bool = false
var discarded: bool = false


func _ready():
	calculate_pivot_offset()
	$TitlePanel/Title.set_text("[center]%s[/center]" % card_name)
	#$CardEffect.set_target(enemy)
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % card_description)
	$EnergyPanel/Energy.set_text("[center]%d[/center]" % energy_cost)
	
	#connect("played", scene._on_card_played.bind(self))

func set_discarded(new_discarded: bool) -> void:
		
	discarded = new_discarded
	
		
func reduce_saturation() -> void:
	modulate = Color(0.4, 0.4, 0.4, 1.0)
	
func normalize_saturation() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
func calculate_pivot_offset() -> void:
	pivot_offset = size / 2

func _on_gui_input(event):
	
	if event.is_action_pressed("select"):
		if discarded:
			discard_pile_view.populate_cards()
			discard_pile_view.show()
		else:
			grab()
	elif event.is_action_released("select") and not discarded:
		drop()
		
	if event is InputEventMouseMotion and event.relative.length() > 5 and card_preview.visible:
		print("Mouse moved: ", event.relative)
		card_preview.hide()
	elif event is InputEventScreenDrag and event.relative.length() > 5 and card_preview.visible:
		card_preview.hide()

func get_card_effects() -> Array:
	return card_effects

func show_card_preview() -> void:
	# Card preview data
	
	card_preview.clear_extra_descriptions()
	card_preview.set_title(card_name)
	
	for card_effect: CardEffect in card_effects:
		if card_effect.get_effect_description().is_empty():
			continue
			
		var card_effect_name: String = "[font_size=10][b]%s:[/b][/font_size]" % card_effect.get_effect_name()
		var card_effect_description: String = "[font_size=10]%s[/font_size]" % card_effect.get_effect_description()
		var extra_description: String = "%s %s" % [card_effect_name, card_effect_description]
		card_preview.add_extra_description(extra_description)
		
	card_preview.set_background_color(get_background_color())
	card_preview.set_description(card_description)
	card_preview.set_icon_texture(get_icon_texture())
	card_preview.set_energy_cost(energy_cost)
	card_preview.show()
	
func bring_to_front() -> void:
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX

func reset_z_index() -> void:
	z_index = original_z_index

func grab() -> void:
	grabbed = true
	grabbed_timestamp = Time.get_ticks_msec()
	grab_position = position
	bring_to_front()
	
	show_card_preview()
	
	if energy.has_enough_energy(energy_cost):
		play_text.set_text(PLAY_CARD_TEXT)
	else:
		play_text.set_text(LOW_ENERGY_CARD_TEXT)
	#move_to_front()
func can_play() -> bool:
	return card_play_area != null \
		and card_play_area.has_card() \
		and card_play_area.get_card() == self \
		and not enemy.is_animating() \
		and not buffs_container.is_animating() \
		and energy.has_enough_energy(energy_cost)
		
func drop() -> void:
	grabbed = false
	card_preview.hide()
	
	if can_play():
		play()
	else:
		playing = false
		set_position(grab_position)
		reset_z_index()
		
		#if get_parent() is Hand:
			#get_parent().reset_view()

func get_background_color() -> Color:
	return $IconPanel.get_theme_stylebox("panel").bg_color
	
func is_playing() -> bool:
	return playing
	
func play():

	scene.increment_card_count()
	playing = true
	energy.use_energy(energy_cost)
	
	for card_effect in card_effects:
		card_effect.apply()
	
	#last_cards_played_container.add_card(self)
	
	if remember_last_card_effects:
		scene.set_last_card_effects(self)
		buffs_container.activate_on_play_buffs()
	
	set_discarded(true)
	discard_panel.add_card(self)
	
func _process(delta):
	if grabbed:
		global_position = get_global_mouse_position() - size/2

func get_energy_cost() -> int:
	return energy_cost

func get_icon_texture() -> Texture2D:
	return $IconPanel/Icon.get_texture()
