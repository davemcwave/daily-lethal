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
var description_template: String = ""
@export var card_effect_delay: float = 0.0
@export var break_effects_on_apply: bool = false
## Pay the cost after the card's effects instead of before (the default). For
## cards that should see the energy/HP you had before paying: Heartbeat deals
## your HP and Mend/Potion heal first when the cost is paid in HP.
@export var pay_cost_after_effects: bool = false
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
var permanent_card: bool = false
var pending_return_to_hand: bool = false

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
	$TitlePanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % card_name)
	_fit_title.call_deferred()
	$TitlePanel/Title.resized.connect(_fit_title)
	#$CardEffect.set_target(enemy)
	set_description(card_description)
	
	set_energy_text(energy_cost)
	
	$IconPanel/Icon.material = load("res://Resources/WobbleMaterial.tres")
	add_to_group("Cards")
	#connect("played", scene._on_card_played.bind(self))
	
	if is_playing_on_desktop():
		connect("mouse_entered", _on_mouse_entered)
		connect("mouse_exited", _on_mouse_exited)
	
func add_gradient_background(new_colors: PackedColorArray) -> void:
	if has_gradient_background():
		get_node("IconPanel/GradientBackground").queue_free()
	var gradient_background: GradientBackground = load("res://Scenes/GradientBackground.tscn").instantiate()
	gradient_background.set_colors(new_colors)
	# Inset like the built-in cards' gradients, so the icon panel's border shows.
	gradient_background.offset_left = 2.0
	gradient_background.offset_right = -2.0
	gradient_background.offset_bottom = -2.0
	$IconPanel.add_child(gradient_background)
	$IconPanel.move_child(gradient_background,0)
	
	
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
	_card_preview_is_mine = false
	# The formula and status highlights follow "held over the play area" only
	# (_update_live_damage_text). Hiding them here made them vanish mid-drag: the
	# card trails the cursor, so the mouse briefly leaves it on a slow drag.
	
func get_id() -> int:
	return id
	
func set_id(new_id: int) -> void:
	id = new_id
	
func set_state(new_state: State) -> void:
	if new_state == state:
		return
		
	state = new_state
	if new_state != State.Grabbed:
		_stop_damage_preview()  # played, dropped or discarded: the math panel goes at once

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
	var choosing_button: ChoosingButton = load("res://Scenes/ChoosingButton.tscn").instantiate()
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
	card_preview.set_description(_current_description_text())
	_card_preview_is_mine = true
	card_preview.set_icon_texture(get_icon_texture())
	card_preview.set_energy_cost(energy_cost)
	
	if has_gradient_background():
		card_preview.set_gradient_background_texture(get_gradient_background_texture())
	else:
		card_preview.hide_gradient_background()
	card_preview.show()
	
	scene.emit_card_preview_signal()
	
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

func is_in_hand() -> bool:
	return state == State.InHand
	
func get_state() -> State:
	return state
	
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
		$EnergyPanel/Energy.set_text("[center][color=#%s][shake rate=2.0 level=1 connected=1]%d[/shake][/color][/center]" % [color_hex, energy_cost])
		$EnergyPanel/Icon.self_modulate = Color(color_hex)
	else:
		$EnergyPanel/Energy.set_text("[center][shake rate=2.0 level=1 connected=1]%d[/shake][/center]" % energy_cost)
		$EnergyPanel/Icon.self_modulate = Color.WHITE
func can_play() -> bool:
	print(card_play_area != null,
		 card_play_area.has_card(),
		 card_play_area.get_card() == self ,
		 card_play_area != null and card_play_area.is_useable(),
		 scene != null and not scene.is_card_resolving(),
		 not enemy.is_animating(),
		 not buffs_container.is_animating(),
		 can_pay_cost(energy_cost))
		
	return card_play_area != null \
		and card_play_area.has_card() \
		and card_play_area.get_card() == self \
		and card_play_area.is_useable() \
		and scene != null \
		and not scene.is_card_resolving() \
		and not enemy.is_animating() \
		and not buffs_container.is_animating() \
		and can_pay_cost(energy_cost)

func can_play_for_resolver() -> bool:
	if card_play_area != null and not card_play_area.is_useable():
		return false
	if scene != null and scene.is_card_resolving():
		return false
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
	return get_damage_card_effects().size() > 0  # was ">= 0": every card counted as an attack

func set_queue_free_after_applying_card_effects(new_queue_free_after_applying_card_effects: bool) -> void:
	queue_free_after_applying_card_effects = new_queue_free_after_applying_card_effects

func card_queue_free_after_applying_card_effects() -> bool:
	return queue_free_after_applying_card_effects

var pending_trash: bool = false  # trash_when_done() during this card's play

func schedule_return_to_hand_after_resolution() -> void:
	pending_return_to_hand = true
	
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
	
	
func begin_play_resolution() -> void:
	_stop_damage_preview()  # the card is being played: no math panel left behind
	# Record the play before its effects run, so picks/effect choices it triggers
	# (even ones Reverberate, Burst or Overload trigger) attach to this card.
	var background = get_node_or_null("/root/Background")
	if background != null:
		background.record_solution_play(get_scene_file_path())
	if card_play_area != null:
		card_play_area.set_useable(false)
	if scene != null:
		scene.notify_card_started_playing(self)
		# "Last card played" is this card from the moment it's played (statuses
		# that react to it, like Trash and Return, see it during its effects).
		# The replay data Echo/Reverberate use still updates after its effects.
		scene.set_last_card_played(self)

func finish_play_resolution() -> void:
	if buffs_container != null:
		buffs_container.release_attack_statuses()  # this card's attack statuses are done
	if pending_trash:
		pending_trash = false
		pending_return_to_hand = false
		# Already on its way out (Tribute trashes itself, and Haunt's Trash also
		# marked it): waiting on its shrink would outlive it, and the play would
		# never finish (the play area stayed locked).
		if not is_queued_for_deletion():
			await _trash_now()
	if scene != null:
		scene.notify_card_finished_playing(self)
	if card_play_area != null and (scene == null or not scene.is_game_over()):
		card_play_area.set_useable(true)
	if pending_return_to_hand:
		pending_return_to_hand = false
		call_deferred("_return_card_to_hand_from_discard")

## Trash this card (Trash, Corrode). If it's still being played, it's trashed at
## the end of its play instead (freeing it mid-play cuts its remaining effects
## short and leaves the game stuck, e.g. Scrap's discard chooser), and the play
## only counts as finished once it's gone. Only once per card.
func trash_when_done() -> void:
	if has_meta("trashing"):
		return
	set_meta("trashing", true)
	if scene != null and scene.resolving_card_stack.has(self):
		pending_trash = true  # finish_play_resolution() trashes it
		return
	await _trash_now()

func _trash_now() -> void:
	shrink(0.15)
	await get_tree().create_timer(0.15).timeout
	queue_free()
	if discard_panel != null:
		discard_panel.update_discard_count()

func _return_card_to_hand_from_discard() -> void:
	if discard_panel != null:
		discard_panel.remove_card(self)
	set_state(State.InHand)
	normalize_saturation()
	set_rotation(0)
	scale = Vector2.ONE
	if hand != null:
		hand.add_card(self)
		hand.reorder_cards_by_x_position()
	if scene != null:
		scene.set_last_card_played(self)

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	if not pay_cost_after_effects:
		pay_cost(energy_cost)
	await apply_card_effects()
	if pay_cost_after_effects:
		pay_cost(energy_cost)
	print("### applied card effects")
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	await enemy.activate_on_card_play_debuffs()
	await discard()
	scene.check_game_over()
	finish_play_resolution()

func discard() -> void:
	var card_removed_before_discard = not is_inside_tree() or is_queued_for_deletion()
	if is_playing_on_desktop() and is_instance_valid(card_preview):
		if is_connected("mouse_entered", self.show_card_preview):
			disconnect("mouse_entered", self.show_card_preview)
		if is_connected("mouse_exited", card_preview.hide):
			disconnect("mouse_exited", card_preview.hide)
		
	set_state(State.Discarded)
	
	if card_removed_before_discard:
		discard_panel.update_discard_count()
		return
	
	await discard_panel.add_card(self)
	#hand.update_card_separation()

func is_offscreen_right() -> bool:
	var panel_right = global_position.x + size.x
	var screen_right = get_viewport().size.x
	print("%d > %d: %s" % [panel_right, screen_right, panel_right > screen_right])
	return panel_right > screen_right

func _process(delta):
	_live_damage_frames += 1
	if _live_damage_frames >= (2 if state == State.Grabbed else 12):  # quick while dragging
		_live_damage_frames = 0
		_update_live_damage_text()
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

func set_description_template(new_template: String) -> void:
	description_template = new_template if new_template is String else ""
	update_description_panel()

func get_description_template() -> String:
	return description_template

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
	var inner_text: String = card_description
	if not description_template.is_empty():
		if description_template.find("{{") != -1:
			inner_text = _render_description_template(description_template)
		else:
			inner_text = description_template
		card_description = inner_text
	$DescriptionPanel/Title.set_text("[center][shake rate=2.0 level=1 connected=1]%s[/shake][/center]" % inner_text)

func _render_description_template(template: String) -> String:
	if template.is_empty():
		return template
	var regex := RegEx.new()
	if regex.compile("\\{\\{\\s*([^\\}]+)\\s*\\}\\}") != OK:
		return template
	var rendered := ""
	var last_end := 0
	var match_search = regex.search(template)
	while match_search != null:
		var start_index := match_search.get_start(0)
		rendered += template.substr(last_end, start_index - last_end)
		var token := match_search.get_string(1).strip_edges()
		rendered += _resolve_description_template_token(token)
		last_end = match_search.get_end(0)
		match_search = regex.search(template, last_end)
	rendered += template.substr(last_end)
	return rendered

func _resolve_description_template_token(token: String) -> String:
	if token.begins_with("card."):
		var card_key := token.substr(5)
		return str(_resolve_card_template_value(card_key))
	elif token.begins_with("effect"):
		var dot_index := token.find(".")
		if dot_index == -1:
			return ""
		var index_text := token.substr(6, dot_index - 6)
		if not index_text.is_valid_int():
			return ""
		var property_path := token.substr(dot_index + 1)
		if property_path.is_empty():
			return ""
		return _format_template_value(_resolve_effect_template_value(int(index_text), property_path))
	return ""

## How a setting reads on the card: 3.0 -> "3" (card data comes from JSON),
## res://Scenes/SharpBuff.tscn -> "Sharp", a list of cards -> "Slash, Spear".
func _format_template_value(value) -> String:
	if value == null:
		return ""
	if value is float and is_equal_approx(value, roundf(value)):
		return str(int(value))
	if value is Resource and not value.resource_path.is_empty():
		return _scene_display_name(value.resource_path)
	if value is String and (value.begins_with("res://") or value.begins_with("uid://")):
		return _scene_display_name(value)
	if value is Array:
		var parts: PackedStringArray = []
		for item in value:
			parts.append(_format_template_value(item))
		return ", ".join(parts)
	return str(value)

## "res://Scenes/SharpBuff.tscn" -> "Sharp", ".../ReturnCardToHandBuff.tscn" ->
## "Return Card To Hand", ".../SlashCard.tscn" -> "Slash", a uid:// path too.
func _scene_display_name(path: String) -> String:
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if not ResourceUID.has_id(id):
			return path
		path = ResourceUID.get_id_path(id)
	var base := path.get_file().get_basename()
	for suffix in ["Debuff", "Buff", "Card"]:
		if base.ends_with(suffix) and base.length() > suffix.length():
			base = base.trim_suffix(suffix)
			break
	return base.capitalize()

func _resolve_card_template_value(property_name: String):
	match property_name:
		"name":
			return card_name
		"energy", "energy_cost":
			return energy_cost
		"description":
			return card_description
		_:
			var getter := "get_%s" % property_name
			if has_method(getter):
				return call(getter)
	return ""

func _resolve_effect_template_value(effect_index: int, property_path: String):
	if effect_index < 0 or effect_index >= card_effects.size():
		return ""
	var value: Variant = card_effects[effect_index]
	if value == null:
		return ""
	var segments: PackedStringArray = property_path.split(".", false)
	for segment in segments:
		value = _resolve_template_segment(value, segment)
		if value == null:
			return ""
	return value

func _resolve_template_segment(source, segment: String):
	if source == null:
		return null
	match typeof(source):
		TYPE_OBJECT:
			return _resolve_object_member(source, segment)
		TYPE_DICTIONARY:
			return source.get(segment, null)
		TYPE_ARRAY:
			if segment.is_valid_int():
				var idx := int(segment)
				if idx >= 0 and idx < source.size():
					return source[idx]
			return null
		_:
			return null

## "LessThan,GreaterThan:5" with 5 -> "GreaterThan"; unknown values stay numbers.
func _enum_label(hint_string: String, value: int):
	var next_value := 0
	for option in hint_string.split(","):
		var option_value := next_value
		if option.contains(":"):
			option_value = option.get_slice(":", 1).to_int()
		if option_value == value:
			return option.get_slice(":", 0).strip_edges().capitalize()
		next_value = option_value + 1
	return value

func _resolve_object_member(obj: Object, member: String):
	if obj == null:
		return null
	for property in obj.get_property_list():
		if property.has("name") and property["name"] == member:
			var value = obj.get(member)
			# A dropdown setting stored as a number reads as its label ("LessThan", not 0).
			if value is int and property.get("hint", 0) == PROPERTY_HINT_ENUM:
				return _enum_label(str(property.get("hint_string", "")), value)
			return value
	var getter := "get_%s" % member
	if obj.has_method(getter):
		return obj.call(getter)
	if member.begins_with("get_") and obj.has_method(member):
		return obj.call(member)
	return null

# ---------------------------------------------------------- hover damage preview

var _damage_preview_label: RichTextLabel = null
var _damage_preview_panels: Array = []

## What playing this card now would do with its attacks, using the live attack
## tiers (add, multiply, convert, split, Vulnerable per hit, after). Changes
## nothing. {"has_attack", "total", "base_total", "lines" (BBCode formulas),
## "panels" (the status boxes it would use, to highlight), "repeats"}.
func get_damage_preview() -> Dictionary:
	var result := {"has_attack": false, "total": 0, "base_total": 0, "per_effect": [], "lines": [], "panels": []}
	if buffs_container == null or enemy == null:
		return result
	var used: Array = []
	var uses_left: Dictionary = {}
	var charged: Dictionary = {}  # attack statuses this card's earlier hits used: its later hits get them too
	var bonus: int = enemy.get_incoming_damage_bonus()
	# Like Slay the Spire, the number is for one play: Repeat (which plays the card
	# again) isn't added in, just noted and highlighted.
	var repeat_panel = null
	for panel in buffs_container.get_children():
		if is_instance_valid(panel) and is_instance_valid(panel.get_buff()) and panel.get_buff().scene_file_path.ends_with("RepeatBuff.tscn"):
			repeat_panel = panel
	result["repeats"] = repeat_panel != null
	# get_card_effects() includes the options of a choice (Potion: damage or heal), so a
	# chosen attack gets the same preview as any other.
	for effect in get_card_effects():
		if not (effect is DamageCardEffect) or effect.target_name != "Enemy":
			continue
		result["has_attack"] = true
		var context := {"current_damage_amount": effect.get_preview_damage_amount(), "deal_damage": true, "used": used, "uses_left": uses_left, "charged": charged}
		result["base_total"] += context["current_damage_amount"]
		var start_amount: int = context["current_damage_amount"]  # the number the card's text shows
		var steps: Array = effect.get_preview_start_steps()
		for acted in buffs_container.preview_buffs(Buff.ActivationType.OnAttack, context):
			steps.append(acted["note"])
			result["panels"].append(acted["panel"])
		var dealt := 0
		var hit_count := 1
		var per_hit := 0
		if context["deal_damage"] and context["current_damage_amount"] > 0:
			# Deal damage step: Vulnerable adds to each hit.
			var hits: Array = context.get("hits", [context["current_damage_amount"]])
			hit_count = hits.size()
			per_hit = int(hits[0]) + bonus
			for hit in hits:
				dealt += hit + bonus
			if bonus > 0:
				# Split: Vulnerable is added to each piece, after the split.
				steps.append({"op": "+" if hit_count == 1 else "each", "value": bonus, "name": "vulnerable"})
				for panel in enemy.get_node("DebuffContainer").get_children():
					if is_instance_valid(panel.get_debuff()) and panel.get_debuff().get_incoming_damage_bonus() > 0:
						result["panels"].append(panel)
		context["damage_dealt"] = dealt  # what Lifesteal heals: all of it, Vulnerable included
		for acted in buffs_container.preview_buffs(Buff.ActivationType.React, context):
			steps.append(acted["note"])
			result["panels"].append(acted["panel"])
		result["total"] += dealt
		# The number the card shows: what it deals in total (a split attack too; the
		# formula shows the pieces); when converted (Charge, Flame, Poison), the
		# amount converted.
		var shown: int = dealt if context["deal_damage"] else context["current_damage_amount"]
		# What a converter turns the damage into ("charge", "flame", "poison"), if any.
		var converted := ""
		if not context["deal_damage"]:
			for step: Dictionary in steps:
				if step.get("op") == "to" and step.get("name") != "splinter":
					converted = step["name"]
		result["per_effect"].append({"base": start_amount, "dealt": dealt, "shown": shown,
			"hits": hit_count if context["deal_damage"] else 1, "converted": converted})
		# One formula: the first hit's, the one that sets the number on the card
		# (Flurry's other strikes don't add lines). Only when something changed it.
		if steps.size() > 1 and result["per_effect"].size() == 1:
			result["lines"].append(_damage_formula(steps, dealt, shown, hit_count, per_hit))
	if repeat_panel != null and result["has_attack"]:
		result["panels"].append(repeat_panel)  # highlighted, but not in the formula (attack math only)
	return result

## One format for every attack: each step in attack order, its name in
## parentheses, with the running total, ending in the damage:
##   4 (base) » +2 (sharp) = 6 » x2 (critical) = 12 » +1 (vulnerable) = 13 damage
##   4 (base) » x2 (critical) = 8 » 8 hits of 1 (splinter) » +1 each (vulnerable) = 16 damage » heal 16 (lifesteal)
##   5 (base) converts to 5 Vulnerable (poison)
func _damage_formula(steps: Array, dealt: int, shown: int, hit_count: int = 1, per_hit: int = 0) -> String:
	var name_of := func(name: String) -> String:
		return "[color=#9fb0b6](%s)[/color]" % name
	# Each segment: [text with %s where its total goes, total or -1]
	var segments: Array = []
	var running := 0
	for step: Dictionary in steps:
		match step.get("op"):
			"start":
				running = step["value"]
				segments.append(["%d %s%%s" % [running, name_of.call(step["name"])], running])
			"+":
				running += step["value"]
				segments.append(["+%d %s%%s" % [step["value"], name_of.call(step["name"])], running])
			"x":
				running *= step["value"]
				segments.append(["x%d %s%%s" % [step["value"], name_of.call(step["name"])], running])
			"to":
				if hit_count > 1 and step["name"] == "splinter":
					# Joins the line before: "5 (base) converts to 5 hits of 1 (splinter)"
					segments.append(["converts to %d hits of 1 %s%%s" % [hit_count, name_of.call("splinter")], SPLIT])
				else:
					# Joins the line before: "5 (base) converts to 5 Vulnerable (poison)"
					segments.append(["converts to %s %s" % [step["text"], name_of.call(step["name"])], CONVERTED])
			"each":
				segments.append(["+%d each hit %s%%s" % [step["value"], name_of.call(step["name"])], dealt])
			"after":
				segments.append(["%s %s" % [step["text"], name_of.call(step["name"])], REACTION])  # "heal 24 (lifesteal)"
	# The damage goes on the last number before a conversion or a reaction; on a
	# split attack with nothing added per hit, on the split itself.
	var last := -1
	var split_at := -1
	for i in segments.size():
		if segments[i][1] == CONVERTED or segments[i][1] == REACTION:
			break
		if segments[i][1] == SPLIT:
			split_at = i
			last = i
		elif segments[i][1] >= 0:
			last = i
	var damage_text := " = [b][color=#fbbf24]%d damage[/color][/b]" % dealt
	var parts: Array[String] = []
	for i in segments.size():
		var text: String = segments[i][0]
		var total: int = segments[i][1]
		if i == split_at:
			var split_text := text % (damage_text if i == last and dealt > 0 else "")
			if parts.is_empty():
				parts.append(split_text)
			else:
				parts[parts.size() - 1] += " " + split_text
		elif total == CONVERTED and not parts.is_empty():
			parts[parts.size() - 1] += " " + text  # on the same line as the amount it converts
		elif total < 0:
			parts.append(text)  # reaction: no running total
		elif i == last and dealt > 0:
			parts.append(text % (" = [b][color=#fbbf24]%d damage[/color][/b]" % dealt))
		elif i == 0:
			parts.append(text % "")  # "4 (base)"
		else:
			parts.append(text % (" = %d" % total))
	return "
".join(parts)

const SPLIT := -1
const CONVERTED := -2
const REACTION := -3

func _show_damage_preview() -> void:
	var preview := get_damage_preview()
	# Every status that will act when this card is played lights up, attack or not.
	for panel in _statuses_acting_on_this_card():
		if not preview["panels"].has(panel):
			preview["panels"].append(panel)
	if not preview["has_attack"]:
		_highlight_status_panels(preview["panels"])
		return
	if _damage_preview_label == null:
		_damage_preview_label = RichTextLabel.new()
		_damage_preview_label.bbcode_enabled = true
		_damage_preview_label.fit_content = true
		_damage_preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_damage_preview_label.scroll_active = false
		_damage_preview_label.top_level = true
		_damage_preview_label.z_index = 100
		_damage_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_damage_preview_label.add_theme_font_size_override("normal_font_size", 12)
		_damage_preview_label.add_theme_font_size_override("bold_font_size", 12)
		_damage_preview_label.add_theme_color_override("default_color", Color("#f3efe4"))
		_damage_preview_label.add_theme_constant_override("line_separation", 2)
		var backing := StyleBoxFlat.new()  # like a card: dark face, light rim
		backing.bg_color = Color("#1d262b")
		backing.set_border_width_all(2)
		backing.border_color = Color("#5b6b72")
		backing.set_corner_radius_all(8)
		backing.content_margin_left = 9
		backing.content_margin_right = 9
		backing.content_margin_top = 6
		backing.content_margin_bottom = 6
		_damage_preview_label.add_theme_stylebox_override("normal", backing)
		add_child(_damage_preview_label)
	# The math, one step per line, beside the card (Options: Show damage math).
	_damage_preview_label.text = "\n".join(preview["lines"])
	_damage_preview_label.size = Vector2.ZERO
	_damage_preview_label.reset_size()
	await get_tree().process_frame  # let fit_content measure the text
	if not is_instance_valid(_damage_preview_label):
		return
	_place_damage_math()
	_damage_preview_label.visible = _show_damage_math() and not preview["lines"].is_empty()
	_highlight_status_panels(preview["panels"])

## Lights up these status boxes (the visible box for grouped buffs).
func _highlight_status_panels(panels: Array) -> void:
	_hide_damage_preview_highlights()
	_damage_preview_panels = []
	for panel in panels:
		if panel is BuffPanel and panel.get_parent() != null and panel.get_parent().has_method("get_shown_panel"):
			panel = panel.get_parent().get_shown_panel(panel)  # grouped: light up the visible box
		if not _damage_preview_panels.has(panel):
			_damage_preview_panels.append(panel)
	for panel in _damage_preview_panels:
		if is_instance_valid(panel) and panel.has_method("set_highlighted"):
			panel.set_highlighted(true)

func _hide_damage_preview() -> void:
	if _damage_preview_label != null:
		_damage_preview_label.hide()
	_hide_damage_preview_highlights()

## Hides the math panel and status highlights now (not on the next text update, which
## may not come once the card is played and on its way to the discard pile).
func _stop_damage_preview() -> void:
	_formula_showing = false
	_hide_damage_preview()

func _hide_damage_preview_highlights() -> void:
	for panel in _damage_preview_panels:
		if is_instance_valid(panel) and panel.has_method("set_highlighted"):
			panel.set_highlighted(false)
	_damage_preview_panels = []

# ------------------------------------------------------ live damage in the card text

var _live_damage_frames := 0
var _formula_showing := false
var _text_original := ""  # the card's own description (BBCode), without a live number
var _text_shown := ""	 # what we last put in the description

## While you hold the card over the play area (about to play it, like dragging an
## attack onto an enemy in Slay the Spire), the damage number in its own text
## shows what it would deal, in gold when your statuses change it (up or down; a
## conversion makes it 0). Anywhere else it shows its normal text. Multi-hit cards
## show the first hit. Cards with no number in their text (Heartbeat, Shovel) keep
## their text; hovering shows the formula either way.
func _update_live_damage_text() -> void:
	var title: RichTextLabel = get_node_or_null("DescriptionPanel/Title")
	if title == null:
		return
	if title.text != _text_shown:
		_text_original = title.text  # the card (re)wrote its text: start from that
	var base_text := _text_original
	# Count-based cards (Heartbeat: "equal to your HP") get "(Deals N damage)" in
	# hand, with the live amount.
	var counted := _first_enemy_damage_effect()
	if counted != null and counted.is_count_based() and state in [State.InHand, State.Grabbed, State.Choosing, State.Discarded]			 and buffs_container != null:
		base_text = _insert_before_closing_tags(_text_original, " (Deals %d damage)" % counted.get_preview_damage_amount())
	var wanted := base_text
	var converted := ""
	if _is_over_play_area() and buffs_container != null and enemy != null:
		var preview := get_damage_preview()
		if preview["has_attack"] and not preview["per_effect"].is_empty():
			var first: Dictionary = preview["per_effect"][0]
			converted = first.get("converted", "")
			if first["shown"] != first["base"] or first["dealt"] != first["shown"]:
				var color := "#fbbf24"  # gold: this number is changed by your statuses (up or down)
				wanted = _replace_first_number(base_text, first["base"],
					"[outline_size=7][outline_color=#3b2400][pulse freq=2.0 color=#fff6c9 ease=-2.0][color=%s]%d[/color][/pulse][/outline_color][/outline_size]" % [color, first["shown"]])
	if counted != null:
		wanted = _color_damage_words(wanted, converted)
	if wanted != title.text:
		title.text = wanted
		if _card_preview_is_mine and card_preview != null and card_preview.visible:
			card_preview.set_description(_current_description_text())  # keep the hover preview in step
	_text_shown = wanted
	_fit_description(title)
	# The formula and the pulsing statuses, also only while over the play area
	# (switched on/off once, so the pulse doesn't restart).
	var over := _is_over_play_area()
	if over and not _formula_showing:
		_formula_showing = true
		_show_damage_preview()
	elif not over and _formula_showing:
		_formula_showing = false
		_hide_damage_preview()
	if _formula_showing and _damage_preview_label != null:
		# Follow the card while it's dragged.
		_place_damage_math()

## Replaces the first standalone `number` in the text, outside [bbcode] tags (so
## "[shake rate=2.0 ...]" and "[color=#c35300]" are left alone).
## What "Deal N damage" becomes on a held attack that a status will convert:
## [verb, what, color]. Onto the enemy: "Apply"; onto you (Charge): "Gain".
const CONVERTED_PHRASES := {
	"charge": ["Gain", "energy", "#f1c40f"],
	"flame": ["Apply", "Burn", "#e67e22"],
	"poison": ["Apply", "Vulnerable", "#e67e22"],
}

## Damage cards keep their own text (the number in red, as the card writes it). Only
## when the attack will be converted (Charge, Flame, Poison) does the first "Deal N
## damage" change, into what it turns into, in that status's color: "Apply 3
## Vulnerable", "Gain 3 energy". Cards without "Deal N damage" ("Deal damage equal
## to your HP") get the word "damage" replaced the same way.
static func _color_damage_words(text: String, converted: String) -> String:
	if not CONVERTED_PHRASES.has(converted):
		return text
	var to: Array = CONVERTED_PHRASES[converted]
	var phrase := RegEx.create_from_string("\\b([Dd]eal) ((?:\\[[^\\]]*\\])*\\d+(?:\\[[^\\]]*\\])*) damage\\b")
	var found := phrase.search(text)
	if found != null:
		var verb := found.get_string(1)
		var new_verb: String = to[0] if verb.begins_with("D") else to[0].to_lower()
		var piece := "[color=%s]%s %s %s[/color]" % [to[2], new_verb, found.get_string(2), to[1]]
		return text.substr(0, found.get_start()) + piece + text.substr(found.get_end())
	var pattern := RegEx.create_from_string("\\[[^\\]]*\\]|\\b(damage)\\b")
	for word in pattern.search_all(text):
		if word.get_string(1).is_empty():
			continue  # a tag
		return text.substr(0, word.get_start(1)) + "[color=%s]%s[/color]" % [to[2], to[1]] + text.substr(word.get_end(1))
	return text

static func _replace_first_number(text: String, number: int, replacement: String) -> String:
	var pattern := RegEx.create_from_string("\\[[^\\]]*\\]|(?<![\\d.])(\\d+)(?![\\d.])")
	for found in pattern.search_all(text):
		if found.get_string(1).is_empty():
			continue  # a tag
		if found.get_string(1).to_int() == number:
			return text.substr(0, found.get_start(1)) + replacement + text.substr(found.get_end(1))
	return text

## Held over the play area, about to be played.
func _is_over_play_area() -> bool:
	return state == State.Grabbed and card_play_area != null and card_play_area.has_card()		 and card_play_area.get_card() == self

## The card's first damage effect aimed at the enemy, or null.
func _first_enemy_damage_effect() -> DamageCardEffect:
	for effect in get_card_effects():  # includes a choice's options (Potion)
		if effect is DamageCardEffect and effect.target_name == "Enemy":
			return effect
	return null

## Puts text in before the closing [/shake][/center] tags at the end.
static func _insert_before_closing_tags(text: String, addition: String) -> String:
	var found := RegEx.create_from_string("(\\[/[a-z_]+\\])*\\s*$").search(text)
	var at := found.get_start() if found != null else text.length()
	return text.substr(0, at) + addition + text.substr(at)

## The status boxes (yours and the enemy's) that would act if this card were
## played now, besides the attack-step ones from the damage preview.
func _statuses_acting_on_this_card() -> Array:
	var panels: Array = []
	if buffs_container == null or enemy == null:
		return panels
	for panel in buffs_container.get_children():
		if panel is BuffPanel and is_instance_valid(panel.get_buff()) and panel.get_buff().would_act_on_card(self):
			panels.append(panel)
	for buff in enemy.get_buffs():
		if is_instance_valid(buff) and is_instance_valid(buff.buff_panel) and buff.would_act_on_card(self):
			panels.append(buff.buff_panel)
	for panel in enemy.get_node("DebuffContainer").get_children():
		if is_instance_valid(panel.get_debuff()) and panel.get_debuff().would_act_on_card(self):
			panels.append(panel)
	return panels

## The damage math beside a held attack, one step per line ("4 (base)", "+2 (sharp)
## = 6", ...). On by default; players can turn it off in Options ("Show damage
## math", Background.show_damage_math).
func _show_damage_math() -> bool:
	var background = get_node_or_null("/root/Background")
	return background != null and background.get("show_damage_math") == true

## Right of the card, or left of it near the screen's right edge; kept on screen.
func _place_damage_math() -> void:
	if _damage_preview_label == null:
		return
	# Below the card, centred on it, so it fits narrow (mobile) screens as well as
	# desktop; above the card when there's no room below. Kept on screen.
	var card_rect := get_global_rect()
	var view := get_viewport_rect().size
	var box := _damage_preview_label.size
	var x := card_rect.get_center().x - box.x / 2.0
	x = clampf(x, 4.0, maxf(4.0, view.x - box.x - 4.0))
	var y := card_rect.end.y + 6.0
	if y + box.y > view.y - 4.0:
		y = card_rect.position.y - box.y - 6.0
	y = clampf(y, 4.0, maxf(4.0, view.y - box.y - 4.0))
	_damage_preview_label.global_position = Vector2(x, y)

## No scrollbar on a card's description: text that doesn't fit (Overload's,
## a "(Deals N damage)" line, a long custom card) shrinks a size at a time, down to 7.
const DESCRIPTION_FONT_SIZE := 12
const DESCRIPTION_MIN_FONT_SIZE := 7
const TITLE_FONT_SIZE := 12
const TITLE_MIN_FONT_SIZE := 7

## A long name (a custom card's) shrinks to fit the title box.
func _fit_title() -> void:
	var title: RichTextLabel = get_node_or_null("TitlePanel/Title")
	if title != null:
		TextFit.fit(title, TITLE_FONT_SIZE, TITLE_MIN_FONT_SIZE)
func _fit_description(title: RichTextLabel) -> void:
	title.scroll_active = false
	var font_size: int = title.get_theme_font_size("normal_font_size")
	if title.get_content_height() > title.size.y and font_size > DESCRIPTION_MIN_FONT_SIZE:
		font_size -= 1  # one step per check (~5 times a second) until it fits
	elif font_size < DESCRIPTION_FONT_SIZE and title.get_content_height() + title.get_theme_font("normal_font").get_height(font_size) < title.size.y * 0.75:
		font_size += 1  # room again (the text got shorter): grow back
	for size_name in ["normal_font_size", "bold_font_size"]:
		title.add_theme_font_size_override(size_name, font_size)

var _card_preview_is_mine := false

## The description as the card shows it right now (live count lines included),
## for the big hover preview; it adds its own [center].
func _current_description_text() -> String:
	var title: RichTextLabel = get_node_or_null("DescriptionPanel/Title")
	if title == null or title.text.is_empty():
		return card_description
	return title.text.replace("[center]", "").replace("[/center]", "")
