extends VBoxContainer
class_name EffectPanel

@onready var effect_names: OptionButton = $EffectNames
@onready var effect_inputs: GridContainer = $EffectInputs

func _ready() -> void:
	modulate = Color('7ceef2')
	modulate.h = randf()
	
	create_effect_inputs(effect_names.selected)
	
func create_damage_effect_inputs() -> void:
	for input_name in ['Damage Amount', 'Increase Damage Multiplier']:
		var effect_input: EffectInput = load("res://Scenes/EffectInput.scn").instantiate()
		effect_input.set_input_name(input_name)
		effect_inputs.add_child(effect_input)

func remove_all_effect_inputs() -> void:
	for effect_input in effect_inputs.get_children():
		effect_input.queue_free()
		
func create_effect_inputs(index: int) -> void:
	var effect_name_selected = effect_names.get_item_text(index)
	
	match effect_name_selected:
		"DamageCardEffect":
			create_damage_effect_inputs()

func _on_effect_names_item_selected(index):
	remove_all_effect_inputs()
	create_effect_inputs(index)
			
