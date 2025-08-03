extends Panel
class_name Deck

@onready var hand: Hand = get_tree().get_root().get_node("Scene/Hand")
@onready var cards_amount_text: RichTextLabel = get_tree().get_root().get_node("Scene/CardsAmountText")
@onready var audio_handler: AudioHandler = $"/root/AudioHandler"
func _ready() -> void:
	update_text()
	
func update_text() -> void:
	cards_amount_text.set_text("[center][b]%d[/b][/center]" % get_child_count())
	
func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for child in get_children():
		if child is Card:
			cards.append(child)
	return cards
	
func can_draw_cards(amount: int) -> bool:
	return get_cards().size() >= amount
	
func draw_cards(amount: int) -> Array[Card]:
	var cards: Array[Card] = get_cards()
		
	for i in range(amount):
		var card: Card = cards.pop_front()
		remove_child(card)
		audio_handler.play_sfx("DrawSFX")
		audio_handler.increase_pitch_scale("DrawSFX", 0.05)
		hand.add_card(card)
		await get_tree().create_timer(0.25).timeout
		update_text()

	audio_handler.reset_pitch_scale("DrawSFX")
	return cards
