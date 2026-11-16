class_name CustomCardScene
extends Resource
## A custom card where a card scene is expected (e.g. Pick to Create's card list): holds the
## card's definition (CardFactory format) and makes the card the way PackedScene.instantiate()
## would. In card data it is stored as that definition (EffectRegistry).

var definition: Dictionary = {}

func _init(card_definition: Dictionary = {}) -> void:
	definition = EffectRegistry.without_embedded_cards(card_definition)

func instantiate(_edit_state: int = 0) -> Card:
	return CardFactory.create_card(definition)

func get_card_name() -> String:
	return str(definition.get("name", "Custom Card"))
