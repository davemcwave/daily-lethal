extends CardEffect

@export_enum("Discard Pile", "Hand", "Self") var trash_from_location: String = "Discard Pile"
@export var card_amount: int = 1
@export_enum("Top", "Bottom") var discard_pile_trash_direction: String = "Top"
#@onready var scene: Scene = get_tree().get_root().get_node("Scene")
@onready var hand: Hand = scene.get_node("Hand")
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

func set_card_amount(new_card_amount: int) -> void:
	card_amount = new_card_amount
	
func get_card_amount() -> int:
	return card_amount

func set_trash_from_location(new_trash_from_location: String) -> void:
	trash_from_location = new_trash_from_location

func get_trash_from_location() -> String:
	return trash_from_location
	
func set_discard_pile_trash_direction(new_discard_pile_trash_direction: String) -> void:
	discard_pile_trash_direction = new_discard_pile_trash_direction

func get_discard_pile_trash_direction() -> String:
	return discard_pile_trash_direction
	
func apply() -> void:
	if trash_from_location == "Discard Pile":
		var cards: Array[Card] = discard_panel.get_cards()
		
		if discard_pile_trash_direction == "Bottom":
			cards.reverse()
		
		for i in range(min(cards.size(), card_amount)):
			var card: Card = cards[i]
			card.shrink(0.15)
			await get_tree().create_timer(0.15).timeout
			card.queue_free()
			
	elif trash_from_location == "Hand":
		pass # @TODO
		
	elif trash_from_location == "Self":
		await get_tree().create_timer(0.5).timeout
		var card: Card = get_parent()
		card.shrink(0.15)
		await get_tree().create_timer(0.15).timeout
		card.queue_free()
