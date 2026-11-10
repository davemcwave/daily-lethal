extends TextureRect

@export var CARD_HOVERED_COLOR = Color('1bc46d')
@export var CARD_NORMAL_COLOR = Color('00000042')

var card: Card = null
@onready var play_text: RichTextLabel = $"../PlayText"
@onready var puzzle_author_text: RichTextLabel = $"../PuzzleAuthorText"
@export var useable: bool = true

func _ready():
	self_modulate = CARD_NORMAL_COLOR

func _on_area_2d_area_entered(area):
	_forget_gone_card()
	if area.get_parent() is Card and card == null and useable:
		self_modulate = CARD_HOVERED_COLOR
		card = area.get_parent()
		play_text.show()
		puzzle_author_text.hide()
		card.refresh_energy_text()

func _on_area_2d_area_exited(area):
	_forget_gone_card()
	# Only the card being held over the area leaving counts; another card's area
	# brushing past (a hand card during a slow drag) mustn't drop the held one.
	if card != null and area.get_parent() != card:
		return
	_clear()

func _clear() -> void:
	self_modulate = CARD_NORMAL_COLOR
	if is_instance_valid(card):
		card.set_energy_text(card.get_energy_cost())
		card.set_energy_icon(card.energy_texture)
	card = null
	play_text.hide()
	puzzle_author_text.show()

## A card trashed while it was the area's card (Tribute trashed by Haunt) is freed
## in place, so it never "exits": without this the area would keep pointing at it
## and ignore every card held over it afterwards.
func _forget_gone_card() -> void:
	if card != null and (not is_instance_valid(card) or card.is_queued_for_deletion()):
		_clear()
		_take_held_card_already_over()

func is_useable() -> bool:
	return useable

func set_useable(new_useable: bool) -> void:
	useable = new_useable
	_forget_gone_card()
	if useable and card == null:
		_take_held_card_already_over()

## A card dragged over the area while it was locked (the previous card still
## playing) never "entered" it as far as the area knows: take it now, so it can
## be dropped once the area opens.
func _take_held_card_already_over() -> void:
	if not useable or card != null:
		return
	var area_node := get_node_or_null("Area2D") as Area2D
	if area_node == null:
		return
	for area in area_node.get_overlapping_areas():
		var held = area.get_parent()
		if held is Card and is_instance_valid(held) and not held.is_queued_for_deletion() and held.state == Card.State.Grabbed:
			_on_area_2d_area_entered(area)
			return

func has_card():
	_forget_gone_card()
	return card != null

func get_card() -> Card:
	_forget_gone_card()
	return card
