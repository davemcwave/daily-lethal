extends CardEffect

@export_file("*.scn") var debuff_scene
@export var target: Node = null
var debuff = null
	
func set_target(new_target) -> void:
	target = new_target
	
func apply() -> void:
	debuff = load(debuff_scene).instantiate()
	target.add_debuff(debuff)
