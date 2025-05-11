extends ColorRect
class_name DiscardChooseArea

signal closed

const DISCARD_TEXT = "[center][b]Discard {max_discard_amount} card{card_plural}[/b][/center]"
@onready var hand: Hand = get_tree().get_root().get_node("Scene/Hand")
@export var max_discard_amount: int = 2
var discard_amount: int = 0
var cards_marked_for_discard: Array[Card] = []

func activate_with_max_discard_amount(max_discard_amount: int) -> void:
	set_max_discard_amount(max_discard_amount)
	activate()
	
func activate() -> void:
	discard_amount = 0
	$DiscardButton.disabled = true
	show()
	populate_cards()
	
func set_max_discard_amount(new_max_discard_amount: int) -> void:
	max_discard_amount = new_max_discard_amount
	
	$DiscardText.set_text(DISCARD_TEXT.format({
		"max_discard_amount": max_discard_amount,
		"card_plural": "s" if max_discard_amount > 1 else ""
	}))
	
func get_max_discard_amount() -> int:
	return max_discard_amount
	
func set_discard_amount(new_discard_amount: int) -> void:
	discard_amount = new_discard_amount
	
func get_discard_amount() -> int:
	return discard_amount
	
func clear_cards() -> void:
	for child in $GridContainer.get_children():
		child.queue_free()

func _on_card_marked_for_discard(marked: bool) -> void:
	if marked:
		discard_amount += 1
	else:
		discard_amount -= 1

	# Disable all the unmarked discarding buttons if player 
	# has already chosen max number of cards to discard.
	# Otherwise, enable them beacuse the player has more to 
	# choose to discard.
	var can_show_discard_button: bool = discard_amount < max_discard_amount
	for card: Card in get_all_cards_not_marked_for_discard():
		card.set_can_show_discarding_button(can_show_discard_button)
	$DiscardButton.disabled = can_show_discard_button

func get_all_cards_not_marked_for_discard() -> Array[Card]:
	var cards_not_marked_for_discard: Array[Card] = []
	for card: Card in $GridContainer.get_children():
		if not card.is_marked_for_discard():
			cards_not_marked_for_discard.append(card)
	return cards_not_marked_for_discard


func populate_cards() -> void:
	if hand.get_cards().size() <= 0:
		close()
		return
		
	clear_cards()
	for child in hand.get_cards():
		var new_card: Card = child.duplicate()
		new_card.connect("marked_for_discard", self._on_card_marked_for_discard)
		new_card.set_state(Card.State.Discarding)
		$GridContainer.add_child(new_card)
		new_card.set_id(child.get_id())
		
func close() -> void:
	emit_signal("closed")
	hide()

func _on_discard_button_pressed() -> void:
	for card: Card in $GridContainer.get_children():
		if card.is_marked_for_discard():
			var card_in_hand: Card = hand.get_card_with_id(card.get_id())
			card_in_hand.discard()
	close()
