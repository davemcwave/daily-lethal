extends Buff
class_name DiscountBuff

@export var discount_amount: int = 1

func set_discount_amount(new_discount_amount: int) -> void:
	discount_amount = new_discount_amount
	
func get_discount_amount() -> int:
	return discount_amount
