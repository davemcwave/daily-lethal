extends Node2D
class_name Debuff

@export var debuff_name: String = "Debuff"
@export var debuff_description: String = "Debuffs the target."
@export var unlimited_uses: bool = true

enum ActivationType {OnHurt, OnAttack}
@export var activation_type: ActivationType

var target: Enemy = null
var debuff_panel: DebuffPanel = null

func _ready() -> void:
	add_to_group("Debuffs")

func set_target(new_target: Enemy) -> void:
	target = new_target
	
func set_debuff_panel(new_debuff_panel: DebuffPanel) -> void:
	debuff_panel = new_debuff_panel
	
func set_debuff_name(new_debuff_name: String) -> void:
	debuff_name = new_debuff_name
	
func set_debuff_description(new_debuff_description: String) -> void:
	debuff_description = new_debuff_description
	
func get_debuff_name() -> String:
	return debuff_name
	
func get_debuff_description() -> String:
	return debuff_description
	
func get_target() -> Enemy:
	return target
	
func set_unlimited_uses(new_unlimited_uses: bool) -> void:
	unlimited_uses = new_unlimited_uses
	
func is_unlimited_uses() -> bool:
	return unlimited_uses
	
func is_activated_on_hurt() -> bool:
	return activation_type == ActivationType.OnHurt
	
# TO BE OVERWRITTEN
func activate() -> void:
	pass
