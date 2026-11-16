extends Buff
class_name FreeBuff

## Used when paying for any card.
func would_act_on_card(card: Card) -> bool:
	return true
