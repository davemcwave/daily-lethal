extends DamageCardEffect
class_name DiscardPileBasedDamageCardEffect
## Shovel: 0 base + cards in your discard pile + Rage-style bonuses (damage_bonus).

@onready var discard_pile: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func apply() -> bool:
	var discarded_card_count: int = discard_pile.get_card_count()
	set_damage_amount(discarded_card_count + damage_bonus)
	return await super.apply()

func get_damage_amount() -> int:
	return discard_pile.get_card_count() + damage_bonus

func get_preview_damage_amount() -> int:
	return discard_pile.get_card_count() + damage_bonus

func get_preview_start_steps() -> Array:
	return _count_steps(discard_pile.get_card_count(), "discard pile")

func is_count_based() -> bool:
	return true
