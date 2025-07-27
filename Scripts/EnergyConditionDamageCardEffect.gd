extends DamageCardEffect
class_name EnergyConditionDamageCardEffect

enum ConditionType {
	LessThan,
	GreaterThan,
	EqualTo
}

@export var condition_type = ConditionType.EqualTo
@export var comparison_value: int = 0
@export var if_false_damage_amount: int = 0
@onready var energy: Energy = get_tree().get_root().get_node("Scene/Energy")

func apply() -> void:
	var energy_amount: int = energy.get_energy_amount()
	
	match condition_type:
		ConditionType.EqualTo:
			if energy_amount != comparison_value:
				deal_damage(if_false_damage_amount)
			else:
				deal_damage(damage_amount)
		ConditionType.LessThan:
			if energy_amount >= comparison_value:
				deal_damage(if_false_damage_amount)
			else:
				deal_damage(damage_amount)
		ConditionType.GreaterThan:
			if energy_amount <= comparison_value:
				deal_damage(if_false_damage_amount)
			else:
				deal_damage(damage_amount)
		_:
				deal_damage(damage_amount)
		
