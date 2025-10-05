extends CardsChooseAreaAction
class_name CardsChooseAreaTrashAction

func apply(card: Card) -> bool:
	card.queue_free()
	return super.apply(card)
