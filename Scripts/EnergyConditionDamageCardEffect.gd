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

func _ready():
	super._ready()

func apply() -> void:
	var original_damage_amount: int = damage_amount
	var energy_amount: int = energy.get_energy_amount()
	
	match condition_type:
		ConditionType.EqualTo:
			if energy_amount != comparison_value:
				set_damage_amount(if_false_damage_amount)
			else:
				set_damage_amount(damage_amount)
		ConditionType.LessThan:
			if energy_amount >= comparison_value:
				set_damage_amount(if_false_damage_amount)
			else:
				set_damage_amount(damage_amount)
		ConditionType.GreaterThan:
			if energy_amount <= comparison_value:
				set_damage_amount(if_false_damage_amount)
			else:
				set_damage_amount(damage_amount)
		_:
				set_damage_amount(damage_amount)
	
	super.apply()
	
	# Reset the damage amount for things like Reclaim.
	damage_amount = original_damage_amount
