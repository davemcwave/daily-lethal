extends ColorRect
class_name CardsChooseArea

signal closed
signal chose

@export var max_card_choose_amount: int = 2
@export_multiline var action_name: String = "Discard"
@onready var hand: Hand = get_tree().get_root().get_node("Scene/HandScrollContainer/Hand")
@onready var discard_pile: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")
@onready var audio_handler = get_node("/root/AudioHandler")
@onready var action_button: Button = $ActionButton
@onready var title_label: RichTextLabel = $TitleLabel
@onready var cards_container: GridContainer = $CardsContainer
@onready var card_creator: CardCreator = $CardCreator
var cards_chosen_amount: int = 0
var cards_chosen: Array[Card] = []
var cards_choose_area_action: CardsChooseAreaAction = null
var choose_up_to_amount: bool = false

# Determines if a check, x, or circle is used to denote selected cards.
enum ChooseType {
	Good,
	Bad,
	Neutral
}
var choose_type = ChooseType.Neutral

# Determines whether to populate cards from Hand or from Discard
enum PopulateCardsType {
	FromHand,
	FromDiscard,
	FromCreate
}
var populate_cards_type = PopulateCardsType.FromHand

func activate(new_choose_type = ChooseType.Neutral, new_populate_cards_type = PopulateCardsType.FromHand) -> void:
	cards_chosen_amount = 0
	choose_type = new_choose_type
	populate_cards_type = new_populate_cards_type
	
	if choose_up_to_amount:
		action_button.set_disabled(false)
	else:
		action_button.set_disabled(true)
	
	show()
	populate_cards()
	
func get_choose_type() -> ChooseType:
	return choose_type

func set_choose_up_to_amount(new_choose_up_to_amount: bool) -> void:
	choose_up_to_amount = new_choose_up_to_amount
	
func set_action_name(new_action_name: String) -> void:
	action_name = new_action_name.capitalize()
	action_button.set_text(action_name)
	
func get_title_text() -> String:
	return "{action_name} {choose_up_to_amount} {max_card_choose_amount} card(s)".format({
		"action_name": action_name,
		"choose_up_to_amount": "up to" if choose_up_to_amount else "",
		"max_card_choose_amount": max_card_choose_amount
	})
	
func set_max_card_choose_amount(new_max_card_choose_amount: int) -> void:
	max_card_choose_amount = new_max_card_choose_amount
	
	title_label.set_text("[b]%s[/b]" % get_title_text())
	
func get_max_card_choose_amount() -> int:
	return max_card_choose_amount

func set_cards_choose_area_action(new_cards_choose_area_action: CardsChooseAreaAction) -> void:
	cards_choose_area_action = new_cards_choose_area_action
	add_child(cards_choose_area_action)
	
func apply_action(card: Card) -> bool:
	return await cards_choose_area_action.apply(card)
	
func clear_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

func _on_card_chosen(chosen: bool) -> void:
	if chosen:
		audio_handler.play_sfx("DiscardSFX", 1.0)
		cards_chosen_amount += 1
	else:
		audio_handler.play_sfx("DiscardSFX", 1.25)
		cards_chosen_amount -= 1

	# Disable all the buttons if player 
	# has already chosen max number of cards.
	# Otherwise, enable them beacuse the player has more to choose.
	var card_can_show_choose_button: bool = cards_chosen_amount < max_card_choose_amount
	for card: Card in get_all_cards_not_chosen():
		card.set_can_show_choosing_button(card_can_show_choose_button)
		
	if choose_up_to_amount:
		action_button.disabled = false
	else:
		action_button.disabled = card_can_show_choose_button

func get_all_cards_not_chosen() -> Array[Card]:
	var cards_not_chosen: Array[Card] = []
	for card: Card in cards_container.get_children():
		if not card.is_chosen():
			cards_not_chosen.append(card)
	return cards_not_chosen
	
func get_card_creator() -> CardCreator:
	return card_creator
	
func populate_cards() -> void:
	var card_source = null
	
	match populate_cards_type:
		PopulateCardsType.FromHand:
			card_source = hand
		PopulateCardsType.FromDiscard:
			card_source = discard_pile
		PopulateCardsType.FromCreate:
			card_source = card_creator
		
	if card_source.get_cards().size() <= 0:
		close()
	else:
		clear_cards()
		
		for child in card_source.get_cards():
			var child_scene_file_path = child.get_scene_file_path()
			var new_card: Card = load(child_scene_file_path).instantiate()
			new_card.connect("chosen", self._on_card_chosen)
			new_card.set_state(Card.State.Choosing)
			cards_container.add_child(new_card)
			new_card.set_id(child.get_id())
				
			
func is_closed() -> bool:
	return not visible
	
func close() -> void:
	if cards_choose_area_action != null:
		cards_choose_area_action.queue_free()
	
	#if card_creator != null:
		#card_creator.queue_free()
		
	emit_signal("closed")
	hide()

func get_card_with_id(card_id) -> Card:
	match populate_cards_type:
		PopulateCardsType.FromHand:
			return hand.get_card_with_id(card_id)
		PopulateCardsType.FromDiscard:
			return discard_pile.get_card_with_id(card_id)
		PopulateCardsType.FromCreate:
			return card_creator.get_card_with_id(card_id)
		_:
			return null

func set_cards_chosen(new_cards_chosen: Array[Card]) -> void:
	cards_chosen = new_cards_chosen
	
func get_cards_chosen() -> Array[Card]:
	return cards_chosen

func _on_action_button_pressed() -> void:
	cards_chosen.clear()
	for card: Card in cards_container.get_children():
		if card.is_chosen():
			var card_in_hand: Card = get_card_with_id(card.get_id())
			apply_action(card_in_hand)
			await get_tree().create_timer(0.1).timeout
			cards_chosen.append(card_in_hand)
	
	audio_handler.play_sfx("DiscardSFX", 1.25)
	close()
