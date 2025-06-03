extends DamageCardEffect
class_name DamageIfDiscardEmptyCardEffect

@onready var discard_panel: DiscardPanel = get_tree().get_root().get_node("Scene/DiscardPanel")

func apply() -> void:
	if discard_panel.is_empty():
		target.hurt(damage_amount)
	else:
		target.hurt(0)
		
