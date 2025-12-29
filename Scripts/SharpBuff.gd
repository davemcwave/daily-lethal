extends Buff
class_name SharpBuff

@export var sharp_count: int = 1

func get_buff_name() -> String:
	return buff_name + " " + str(sharp_count)
	
func set_sharp_count(new_sharp_count: int) -> void:
	sharp_count = new_sharp_count
	
func reduce_sharp_count(decrease_value: int = 1) -> void:
	sharp_count -= decrease_value
	
	var buff_panel: BuffPanel = get_parent()
	
	if sharp_count <= 0:
		var scene: Scene = get_tree().get_root().get_node('Scene')
		buff_panel.queue_free()
	else:
		buff_panel.update_text()

func can_merge_with(other_buff: Buff) -> bool:
	return other_buff is SharpBuff

func merge_with(other_buff: Buff) -> void:
	if other_buff is SharpBuff:
		sharp_count += other_buff.sharp_count
		if is_instance_valid(buff_panel):
			buff_panel.update_text()
	
func activate(context: Dictionary = {}) -> bool:
	var activation_type: ActivationType = context['activation_type']
	
	if activation_type == ActivationType.OnAttack:
		var current_damage_amount: int = context['current_damage_amount']
		context['current_damage_amount'] = current_damage_amount + sharp_count
	elif activation_type == ActivationType.OnCardPlay:
		reduce_sharp_count()
	return super.activate(context)
