extends Panel
class_name Card

signal played
signal bounced
signal changed_state(state)
signal chosen(is_chosen: bool)

const PLAY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]PLAY CARD![/pulse][/b][/center]"
const LOW_ENERGY_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]LOW ENERGY[/pulse][/b][/center]"
#const LOW_HEALTH_CARD_TEXT = "[center][b][pulse freq=2.0 color=#ffffff40 ease=-2.0]LOW ENERGY[/pulse][/b][/center]"

@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var card_play_area = scene.get_node("CardPlayArea")
@export var card_effects: Array[CardEffect] = []
@export var card_name: String = "Slash"
@export var energy_cost: int = 1
@export var card_description: String = "Deal 2 damage"
@export var card_effect_delay: float = 0.0
@export var break_effects_on_apply: bool = false
@onready var enemy = scene.get_node("Enemy")
@onready var card_preview = scene.get_node("CanvasLayer/CardPreview")
@onready var energy: Energy = scene.get_node("Energy")
@onready var health: Health = scene.get_node("Health")
@onready var original_position
@onready var cards_played: CardsPlayed = scene.get_node("CardsPlayed")
@onready var hand: Hand = scene.get_node('HandScrollContainer/Hand')
@onready var play_text = scene.get_node("PlayText")
@onready var background = get_node("/root/Background")
#@onready var last_cards_played_container: GridContainer = scene.get_node("LastCardsPlayedContainer")
@onready var original_z_index = z_index
@onready var buffs_container: BuffsContainer = scene.get_node("BuffsContainer")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")
@onready var discard_pile_view = scene.get_node("CanvasLayer/DiscardPileView")
@onready var energy_texture: Texture2D = preload("res://Assets/Textures/bolt-white.png")
@onready var health_texture: Texture2D = preload("res://Assets/Textures/heart-white.png")
@onready var audio_handler: AudioHandler = get_node("/root/AudioHandler")
@onready var cards_choose_area: CardsChooseArea = scene.get_node("CanvasLayer/CardsChooseArea")

var grab_position = Vector2.ZERO
var grab_offset = Vector2.ZERO
var grabbed_timestamp = null
var last_mouse_position = null
var can_chose_choosing_button: bool = true
var id
var queue_free_after_applying_card_effects: bool = false
var permanent_card: bool = true

enum State {
	InHand,
	Playing,
	Choosing,
	Chosen,
	Discarded,
	Bouncing,
	Grabbed,
	Disabled
}
@export var state = State.InHand

var reordering: bool = false

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
	
	if is_playing_on_desktop():
		connect("mouse_entered", _on_mouse_entered)
		connect("mouse_exited", _on_mouse_exited)
	
func no_cards_grabbed() -> bool:
	for card: Card in get_tree().get_nodes_in_group("Cards"):
		if card.is_grabbed():
			return false
	return true

func is_permanent_card() -> bool:
	return permanent_card
	
func get_formatted_state() -> String:
	return State.keys()[state]
	
func set_reordering(new_reordering: bool) -> void:
	reordering = new_reordering
	
func is_reordering() -> bool:
	return reordering
	
func _on_mouse_entered() -> void:
	if no_cards_grabbed() and not is_discarded():
		self.show_card_preview()
	
func reset_buffs() -> void:
	for card_effect: CardEffect in get_card_effects():
		if card_effect is BuffCardEffect:
			card_effect.reset_buff()
	
func _on_mouse_exited() -> void:
	card_preview.hide()
	
func get_id() -> int:
	return id
	
func set_id(new_id: int) -> void:
	id = new_id
	
func set_state(new_state: State) -> void:
	if new_state == state:
		return
		
	state = new_state
	
	emit_signal("changed_state", state)

func set_can_show_choosing_button(new_can_show_choosing_button: bool) -> void:
	can_chose_choosing_button = new_can_show_choosing_button

func card_can_show_choosing_button() -> bool:
	return can_chose_choosing_button
	
func is_discarded() -> bool:
	return state == State.Discarded
		
func is_chosen() -> bool:
	return state == State.Chosen

func is_choosing() -> bool:
	return state == State.Choosing
	
func reduce_saturation() -> void:
	modulate = Color(0.4, 0.4, 0.4, 1.0)
	
func normalize_saturation() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
func calculate_pivot_offset() -> void:
	pivot_offset = size / 2

func is_grabbed() -> bool:
	return state == State.Grabbed
	
func show_choosing_button() -> void:
	var choosing_button: ChoosingButton = load("res://Scenes/ChoosingButton.scn").instantiate()
	choosing_button.set_icon(cards_choose_area.get_choose_type())
	add_child(choosing_button)
	set_state(State.Chosen)
	choosing_button.connect("pressed",self._on_choosing_button_pressed.bind(choosing_button))
	emit_signal("chosen", true)

func _on_choosing_button_pressed(choosing_button: ChoosingButton) -> void:
	choosing_button.hide()
	choosing_button.queue_free()
	set_state(State.Choosing)
	
	emit_signal("chosen", false)
	
func is_playing_on_desktop() -> bool:
	return is_playing_on_desktop_browser() or is_playing_on_desktop_not_browser()
	
func is_playing_on_desktop_not_browser() -> bool:
	return OS.has_feature("linux") or OS.has_feature("macos")  or OS.has_feature("windows") 
	
func is_playing_on_desktop_browser() -> bool:
	return OS.has_feature("web_linuxbsd") or OS.has_feature("web_macos")  or OS.has_feature("web_windows") 
	
func is_playing_on_mobile_browser() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios")

func _on_gui_input(event):
	
	if event.is_action_pressed("select"):
		if is_discarded():
			if not discard_pile_view.visible:
				discard_pile_view.populate_cards()
				discard_pile_view.show()
		elif is_choosing():
			if card_can_show_choosing_button():
				show_choosing_button()
				#show_discarding_button()
		else:
			grab()
	elif event.is_action_released("select") and is_grabbed():
		drop()
		
	#if is_playing_on_desktop_browser():
		#if is_grabbed() and event is InputEventMouseMotion and event.relative.length() > 5 and card_preview.visible:
		#print("Mouse moved: ", event.relative)
		#card_preview.hide()
	if is_playing_on_mobile_browser() and is_grabbed() and event is InputEventScreenDrag and event.relative.length() > 5 and card_preview.visible:
		card_preview.hide()

func get_card_effects(only_top_level_card_effects: bool = false) -> Array:
	if only_top_level_card_effects:
		return card_effects
	elif is_choice_card():
		return $PlayerChooseEffectCardEffect.get_card_effects_to_choose_from() + [$PlayerChooseEffectCardEffect, ]
	else:
		return card_effects

func get_card_name() -> String:
	return card_name

func get_card_description() -> String:
	return card_description
	
func get_card_description_without_bb_code() -> String:
	var rich_text_label_temporary = RichTextLabel.new()
	rich_text_label_temporary.parse_bbcode(card_description)
	return rich_text_label_temporary.get_parsed_text()
	
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
	
	if has_gradient_background():
		card_preview.set_gradient_background_texture(get_gradient_background_texture())
	else:
		card_preview.hide_gradient_background()
	card_preview.show()
	
func bring_to_front() -> void:
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX

func set_original_z_index(new_original_z_index: int) -> void:
	original_z_index = new_original_z_index
	
func reset_z_index() -> void:
	z_index = original_z_index

func grab() -> void:
	audio_handler.play_sfx("GrabSFX", 1.0)
	set_state(State.Grabbed)
	grabbed_timestamp = Time.get_ticks_msec()
	grab_position = position
	bring_to_front()
	grab_offset = get_global_mouse_position() - global_position	
	
	if is_playing_on_mobile_browser():
		show_card_preview()
	elif is_playing_on_desktop():
		card_preview.hide()
	
	if can_pay_cost(energy_cost):
		play_text.set_text(PLAY_CARD_TEXT)
	else:
		play_text.set_text(LOW_ENERGY_CARD_TEXT)
		
	#if is_reordering():
		#show_card_contents(false)

func show_card_contents(do_show: bool) -> void:
	$IconPanel/Icon.set_visible(do_show)

func refresh_energy_text() -> void:
	if buffs_container.has_discount_buff():
		var discounted_cost: int = buffs_container.get_discounted_cost(energy_cost)
		set_energy_text(discounted_cost, "307aff")
	else:
		set_energy_text(energy_cost)
		
	if buffs_container.has_blood_buff():
		set_energy_icon(health_texture)
		$EnergyPanel/Icon.set_position(Vector2(11.0, 7.0))
	else:
		set_energy_icon(energy_texture)
		$EnergyPanel/Icon.set_position(Vector2(10.0, 7.0))

func set_energy_icon(icon_texture: Texture2D) -> void:
	$EnergyPanel/Icon.set_texture(icon_texture)
	

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
	print(card_play_area != null,
		 card_play_area.has_card(),
		 card_play_area.get_card() == self ,
		 not enemy.is_animating(),
		 not buffs_container.is_animating(),
		 can_pay_cost(energy_cost))
		
	return card_play_area != null \
		and card_play_area.has_card() \
		and card_play_area.get_card() == self \
		and not enemy.is_animating() \
		and not buffs_container.is_animating() \
		and can_pay_cost(energy_cost)

func can_play_for_resolver() -> bool:
	return not enemy.is_animating() \
		and not buffs_container.is_animating() \
		and can_pay_cost(energy_cost)
	
		
func drop() -> void:
	card_preview.hide()
	
	show_card_contents(true)
	
	if can_play():
		#audio_handler.play_sfx("PlaySFX")
		play()
	else:
		audio_handler.play_sfx("GrabSFX", 0.8)
		set_state(State.InHand)
		
		if is_reordering():
			hand.queue_sort()
		else:
			set_position(grab_position)
			reset_z_index()
			hand.queue_sort()
			hand.reorder_cards_by_x_position()
		
		
		
		#
	#set_energy_text(energy_cost)
		#if get_parent() is Hand:
			#get_parent().reset_view()

func get_background_color() -> Color:
	return $IconPanel.get_theme_stylebox("panel").bg_color

func has_gradient_background() -> bool:
	return has_node("IconPanel/GradientBackground")
	
func get_gradient_background_texture() -> GradientTexture2D:
	return get_node("IconPanel/GradientBackground").texture
	
func is_playing() -> bool:
	return state == State.Playing

func has_blood_buff_and_can_pay_cost(cost: int) -> bool:
	return buffs_container.has_blood_buff() and health.has_enough_health(cost)
	
func can_pay_cost(cost: int) -> bool:
	return has_blood_buff_and_can_pay_cost(cost) \
		or energy.has_enough_energy(cost)
	
func pay_cost(cost: int, use_free_buff: bool = true) -> void:
	if buffs_container.has_free_buff() and use_free_buff:
		buffs_container.remove_free_buff()
	elif buffs_container.has_discount_buff():
		var discounted_cost: int = buffs_container.get_discounted_cost(cost)
		
		if buffs_container.has_blood_buff():
			health.hurt(discounted_cost)
			buffs_container.remove_blood_buff()
		else:
			energy.use_energy(discounted_cost)
			
		buffs_container.remove_discount_buff()
		
	elif buffs_container.has_blood_buff():
		health.hurt(cost)
		buffs_container.remove_blood_buff()
	else:
		energy.use_energy(energy_cost)

func get_damage_card_effects() -> Array:
	var damage_card_effects = []
	for card_effect: CardEffect in card_effects:
		if card_effect is DamageCardEffect:
			damage_card_effects.append(card_effect)
	return damage_card_effects
	
func is_attack_card() -> bool:
	return get_damage_card_effects().size() >= 0

func set_queue_free_after_applying_card_effects(new_queue_free_after_applying_card_effects: bool) -> void:
	queue_free_after_applying_card_effects = new_queue_free_after_applying_card_effects

func card_queue_free_after_applying_card_effects() -> bool:
	return queue_free_after_applying_card_effects
	
func get_first_damage_card_effect() -> DamageCardEffect:
	return get_damage_card_effects().front()
	
func apply_card_effects() -> bool:
	for card_effect in card_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		
		var card_effect_result = await card_effect.apply()
			
		#if card_effect.does_require_player_input():
			#await card_effect.player_input_finished
			
		if break_effects_on_apply and card_effect_result == false:
			break
			
	if queue_free_after_applying_card_effects:
		queue_free()
		
	return true

func is_choice_card() -> bool:
	for child in get_children():
		if child is PlayerChooseEffectCardEffect:
			return true
	return false
	
func get_player_choice_card_effect() -> CardEffect:
	for card_effect in get_card_effects():
		if card_effect is PlayerChooseEffectCardEffect:
			return card_effect
	return null

func handle_sfx() -> void:
	#audio_handler.reset_pitch_scale("PlaySFX")
	audio_handler.reset_pitch_scale("HurtSFX")
	audio_handler.play_sfx("PlaySFX")
	audio_handler.increase_pitch_scale("PlaySFX", 0.005)

	for card_effect: CardEffect in get_card_effects():
		if card_effect is BuffCardEffect:
			audio_handler.reset_pitch_scale("AddBuffSFX")
		elif card_effect is DamageCardEffect:
			audio_handler.reset_pitch_scale("EnhanceOtherCardsSFX")
	
	
func play():
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	set_state(State.Playing)
	pay_cost(energy_cost)
	await apply_card_effects()
	print("### applied card effects")
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	discard()
	scene.check_game_over()

func discard() -> void:
	if is_playing_on_desktop() and is_instance_valid(card_preview):
		if is_connected("mouse_entered", self.show_card_preview):
			disconnect("mouse_entered", self.show_card_preview)
		if is_connected("mouse_exited", card_preview.hide):
			disconnect("mouse_exited", card_preview.hide)
		
	set_state(State.Discarded)
	
	discard_panel.add_card(self)
	#hand.update_card_separation()

func is_offscreen_right() -> bool:
	var panel_right = global_position.x + size.x
	var screen_right = get_viewport().size.x
	print("%d > %d: %s" % [panel_right, screen_right, panel_right > screen_right])
	return panel_right > screen_right

func _process(delta):
	if state == State.Grabbed:
		global_position = get_global_mouse_position() - grab_offset
		if reordering:
			global_position.y = hand.global_position.y - 10
			await hand.reorder_cards_by_x_position()

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

func inflate(use_current_scale: bool = false) -> bool:
	var original_scale = scale if use_current_scale else Vector2.ONE
	scale = Vector2(1.5, 1.5)
	
	if is_inside_tree():
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		await tween.finished
		
	return true
	

#func _input(event) -> void:
	#if event.is_action_pressed("ui_accept"):
		#print(OS.has_feature())
	
func is_bouncing() -> bool:
	return state == State.Bouncing
	
func update_description_panel() -> void:
	$DescriptionPanel/Title.set_text("[center]%s[/center]" % card_description)
