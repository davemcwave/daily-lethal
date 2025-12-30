extends BuffCardEffect
class_name BuffWithHealthCardEffect

enum ConditionType {LessThan, LessThanOrEqual, GreaterThan, GreaterThanOrEqual, Equal, NotEqual}
enum StackCalculation {DifferenceFromThreshold, FixedAmount, UseHealthValue}

@export var health_threshold: int = 3
@export var condition_type: ConditionType = ConditionType.LessThan
@export var stack_calculation: StackCalculation = StackCalculation.DifferenceFromThreshold
@export var stacks_per_unit: int = 1
@export var base_stack_amount: int = 0
@export var fixed_stack_amount: int = 1
@export var value_divisor: int = 1
@export var clamp_negative_results: bool = true
@export var max_stack_amount: int = 0

@onready var health: Health = scene.get_node("Health") as Health

func apply() -> bool:
	var current_health: int = health.get_health()
	if buff == null:
		return super.apply()

	var stack_amount: int = _calculate_stack_amount(current_health)
	
	audio_handler.play_sfx("AddBuffSFX")
	audio_handler.increase_pitch_scale("AddBuffSFX", 0.25)
	
	if stack_amount <= 0:
		emit_signal("applied")
		return true


	for _i in range(stack_amount):
		var buff_instance: Buff = buff.duplicate(DUPLICATE_USE_INSTANTIATION)
		buffs_container.add_buff(buff_instance)

	emit_signal("applied")
	return true

func _calculate_stack_amount(current_health: int) -> int:
	if not _matches_condition(current_health):
		return 0

	var stack_amount: int = 0
	match stack_calculation:
		StackCalculation.DifferenceFromThreshold:
			stack_amount = base_stack_amount + _calculate_difference(current_health) * _get_stacks_per_unit()
		StackCalculation.FixedAmount:
			stack_amount = base_stack_amount + max(fixed_stack_amount, 0)
		StackCalculation.UseHealthValue:
			stack_amount = base_stack_amount + _calculate_value_based_amount(current_health) * _get_stacks_per_unit()

	if clamp_negative_results:
		stack_amount = max(stack_amount, 0)

	if max_stack_amount > 0:
		stack_amount = min(stack_amount, max_stack_amount)

	return stack_amount

func _get_stacks_per_unit() -> int:
	return max(1, abs(stacks_per_unit))

func _calculate_value_based_amount(current_health: int) -> int:
	var divisor: int = max(1, value_divisor)
	return int(current_health / divisor)

func _calculate_difference(current_health: int) -> int:
	var difference: int = 0
	match condition_type:
		ConditionType.LessThan, ConditionType.LessThanOrEqual:
			difference = health_threshold - current_health
		ConditionType.GreaterThan, ConditionType.GreaterThanOrEqual:
			difference = current_health - health_threshold
		ConditionType.Equal, ConditionType.NotEqual:
			difference = abs(current_health - health_threshold)
	return max(0, difference)

func _matches_condition(current_health: int) -> bool:
	match condition_type:
		ConditionType.LessThan:
			return current_health < health_threshold
		ConditionType.LessThanOrEqual:
			return current_health <= health_threshold
		ConditionType.GreaterThan:
			return current_health > health_threshold
		ConditionType.GreaterThanOrEqual:
			return current_health >= health_threshold
		ConditionType.Equal:
			return current_health == health_threshold
		ConditionType.NotEqual:
			return current_health != health_threshold
	return false
