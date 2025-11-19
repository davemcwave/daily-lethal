extends CardsChooseAreaAction
class_name CardsChooseAreaCopyToHandAction

@onready var hand: Hand = get_tree().get_root().get_node('Scene/HandScrollContainer/Hand')

func apply(card: Card) -> bool:
	hand.add_card(card)
	return super.apply(card)
