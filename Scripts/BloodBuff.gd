extends Buff
class_name BloodBuff

## Used when paying for any card.
func would_act_on_card(card: Card) -> bool:
	return true
