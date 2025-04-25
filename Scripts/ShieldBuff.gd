extends Buff
class_name BlockBuff

@onready var scene = get_tree().get_root().get_node("Scene")

func _ready() -> void:
	set_buff_description("Shields the target from next %d attack%s" % [uses_amount, "s" if uses_amount > 1 else ""])

func activate() -> void:
	target.set_block(true)
	super.activate()
	
