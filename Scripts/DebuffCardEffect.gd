extends CardEffect

@export_file("*.scn") var debuff_scene
@export var target: Node = null
var debuff: Debuff = null

func _ready() -> void:
	debuff = load(debuff_scene).instantiate()
	target = get_tree().get_root().get_node("Scene/Enemy")

func get_effect_name() -> String:
	return debuff.get_debuff_name()
	
func get_effect_description() -> String:
	return debuff.get_debuff_description()
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> void:
	target.add_debuff(debuff)
