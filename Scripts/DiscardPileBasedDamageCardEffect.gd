extends DamageCardEffect
class_name DiscardPileBasedDamageCardEffect

@onready var discard_pile: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func apply() -> void:
	var discarded_card_count: int = discard_pile.get_card_count()
	set_damage_amount(discarded_card_count)
	target.hurt(damage_amount)

func get_damage_amount() -> int:
	return discard_pile.get_card_count()
