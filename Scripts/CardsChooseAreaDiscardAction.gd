extends CardsChooseAreaAction
class_name CardsChooseAreaDiscardAction

func apply(card: Card) -> bool:
	card.discard()
	return super.apply(card)
