extends Panel
class_name Card

signal played
signal bounced
signal changed_state(state)
signal marked_for_discard(marked: bool)

const PLAY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]PLAY CARD![/pulse][/b][/center]"
const LOW_ENERGY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]LOW ENERGY[/pulse][/b][/center]"

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var card_play_area = scene.get_node("CardPlayArea")
@export var card_effects: Array[CardEffect] = []
@export var card_name: String = "Slash"
@export var energy_cost: int = 1
@export var card_description: String = "Deal 2 damage"
@export var card_effect_delay: float = 0.0
@onready var enemy = scene.get_node("Enemy")
@onready var card_preview = scene.get_node("CanvasLayer/CardPreview")
@onready var energy: Energy = scene.get_node("Energy")
@onready var health: Health = scene.get_node("Health")

@onready var cards_played: CardsPlayed = scene.get_node("CardsPlayed")

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
var can_show_discarding_button: bool = true
var id

enum State {
	InHand,
	Playing,
	Discarding,
	Discarded,
	Bouncing,
	Grabbed,
	Disabled
}
@export var state = State.InHand

func _ready():
	id = get_instance_id()
	
	calculate_pivot_offset()
	$TitlePanel/Title.set_text("[center]%s[/center]" % card_name)
	#$CardEffect.set_target(enemy)
	set_description(card_description)
	
	set_energy_text(energy_cost)
	
	$IconPanel/Icon.material = load("res://Resources/WobbleMaterial.res")
	add_to_group("Cards")
	#connect("played", scene._on_card_played.bind(self))

func get_id() -> int:
	return id
	
func set_id(new_id: int) -> void:
	id = new_id
	
func set_state(new_state: State) -> void:
	if new_state == state:
		return
		
	state = new_state
	
	emit_signal("changed_state", state)

func set_can_show_discarding_button(new_can_show_discarding_button: bool) -> void:
	can_show_discarding_button = new_can_show_discarding_button

func card_can_show_discarding_button() -> bool:
	return can_show_discarding_button
	
func is_discarded() -> bool:
	return state == State.Discarded
		
func is_discarding() -> bool:
	return state == State.Discarding
	
func reduce_saturation() -> void:
	modulate = Color(0.4, 0.4, 0.4, 1.0)
	
func normalize_saturation() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
func calculate_pivot_offset() -> void:
	pivot_offset = size / 2

func is_grabbed() -> bool:
	return state == State.Grabbed

func is_marked_for_discard() -> bool:
	for child in get_children():
		if child is DiscardingButton:
			return true
	return false
	
func show_discarding_button() -> void:
	var discarding_button: Button = load("res://Scenes/DiscardingButton.scn").instantiate()
	add_child(discarding_button)
	discarding_button.connect("pressed",self._on_discarding_button_pressed.bind(discarding_button))
	emit_signal("marked_for_discard", true)

func _on_discarding_button_pressed(discarding_button: DiscardingButton) -> void:
	discarding_button.hide()
	discarding_button.queue_free()
	
	emit_signal("marked_for_discard", false)

func _on_gui_input(event):
	
	if event.is_action_pressed("select"):
		if is_discarded():
			if not discard_pile_view.visible:
				discard_pile_view.populate_cards()
				discard_pile_view.show()
		elif is_discarding():
			if card_can_show_discarding_button():
				show_discarding_button()
		else:
			grab()
	elif event.is_action_released("select") and is_grabbed():
		drop()
		
	if event is InputEventMouseMotion and event.relative.length() > 5 and card_preview.visible:
		print("Mouse moved: ", event.relative)
		card_preview.hide()
	elif event is InputEventScreenDrag and event.relative.length() > 5 and card_preview.visible:
		card_preview.hide()

func get_card_effects() -> Array:
	return card_effects

func get_card_name() -> String:
	return card_name
	
func show_card_preview() -> void:
	# Card preview data
	
	card_preview.clear_extra_descriptions()
	card_preview.set_title(card_name)
	
	var card_effect_names: Array[String] = []
	for card_effect: CardEffect in card_effects:
		var card_effect_name: String = "[center][b]%s:[/b][/center]" % card_effect.get_effect_name()
		if card_effect.get_effect_description().is_empty() or card_effect_names.has(card_effect_name):
			continue
			
		var card_effect_description: String = "[center]%s[/center]" % card_effect.get_effect_description()
		var extra_description: String = "%s %s" % [card_effect_name, card_effect_description]
		card_preview.add_extra_description(extra_description)
		card_effect_names.append(card_effect_name)
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
	set_state(State.Grabbed)
	grabbed_timestamp = Time.get_ticks_msec()
	grab_position = position
	bring_to_front()
	
	show_card_preview()
	
	if can_pay_cost(energy_cost):
		play_text.set_text(PLAY_CARD_TEXT)
	else:
		play_text.set_text(LOW_ENERGY_CARD_TEXT)

func refresh_energy_text() -> void:
	if buffs_container.has_discount_buff():
		var discounted_cost: int = buffs_container.get_discounted_cost(energy_cost)
		set_energy_text(discounted_cost, "307aff")
	else:
		set_energy_text(energy_cost)

func set_energy_cost(new_energy_cost: int) -> void:
	energy_cost = new_energy_cost
	
	set_energy_text(energy_cost)
	
func set_energy_text(energy_cost: int, color_hex: String = "") -> void:
	if not color_hex.is_empty():
		$EnergyPanel/Energy.set_text("[center][color=#%s]%d[/color][/center]" % [color_hex, energy_cost])
		$EnergyPanel/Icon.self_modulate = Color(color_hex)
	else:
		$EnergyPanel/Energy.set_text("[center]%d[/center]" % energy_cost)
		$EnergyPanel/Icon.self_modulate = Color.WHITE
func can_play() -> bool:
	return card_play_area != null \
		and card_play_area.has_card() \
		and card_play_area.get_card() == self \
		and not enemy.is_animating() \
		and not buffs_container.is_animating() \
		and can_pay_cost(energy_cost)
		
func drop() -> void:
	card_preview.hide()
	
	if can_play():
		play()
	else:
		set_state(State.InHand)
		set_position(grab_position)
		reset_z_index()
		#
	#set_energy_text(energy_cost)
		#if get_parent() is Hand:
			#get_parent().reset_view()

func get_background_color() -> Color:
	return $IconPanel.get_theme_stylebox("panel").bg_color
	
func is_playing() -> bool:
	return state == State.Playing

func can_pay_cost(cost: int) -> bool:
	return (
		buffs_container.has_blood_buff() and health.get_health() >= cost
	) \
	or energy.has_enough_energy(cost)
	
func pay_cost(cost: int, use_free_buff: bool = true) -> void:
	if buffs_container.has_free_buff() and use_free_buff:
		buffs_container.remove_free_buff()
	elif buffs_container.has_blood_buff():
		health.hurt(cost)
	elif buffs_container.has_discount_buff():
		var discount_buff: DiscountBuff = buffs_container.get_discount_buff()
		var discount_amount: int = discount_buff.get_discount_amount()
		energy.set_energy(energy.get_energy_amount() - max(cost - discount_amount, 0))
		buffs_container.remove_discount_buff()
	else:
		energy.use_energy(energy_cost)
	
func play():
	scene.increment_card_count()
	set_state(State.Playing)
	
	pay_cost(energy_cost)
	
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		card_effect.apply()
		if card_effect.does_require_player_input():
			await card_effect.player_input_finished
	
	buffs_container.activate_on_play_buffs()
	scene.set_last_card_effects(self)
	
	discard()

func discard() -> void:
	set_state(State.Discarded)
	discard_panel.add_card(self)
	
func _process(delta):
	if state == State.Grabbed:
		global_position = get_global_mouse_position() - size/2

func get_energy_cost() -> int:
	return energy_cost

func get_icon_texture() -> Texture2D:
	return $IconPanel/Icon.get_texture()
	
func set_description(new_description: String) -> void:
	card_description = new_description
	update_description_panel()

func bounce(use_current_scale: bool = false) -> void:
	#var previous_state_before_bouncing: State = state
	#set_state(State.Bouncing)
	#var tween = get_tree().create_tween()
	#var original_scale = Vector2.ONE
	#scale = Vector2(1.5, 1.5)
	#tween.tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	#set_state(previous_state_before_bouncing)
	var end_scale = scale if use_current_scale else Vector2.ONE
	scale = Vector2.ONE*0.1
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", end_scale, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
func shrink(duration: float = 0.25) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

func inflate(use_current_scale: bool = false) -> void:
	var original_scale = scale if use_current_scale else Vector2.ONE
	scale = Vector2(1.5, 1.5)
	
	if is_inside_tree():
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	

#func _input(event) -> void:
	#if event.is_action_pressed("ui_accept"):
		#bounce()
	
func is_bouncing() -> bool:
	return state == State.Bouncing
	
func update_description_panel() -> void:
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % card_description)
