extends Control

@onready var background = $"/root/Background"
@onready var effects_vbox_container: VBoxContainer = $EffectLibraryPanel/ScrollContainer/VBoxContainer

func _ready() -> void:
	populate_effects()
	
func populate_effects() -> void:
	for card_effect_scene in background.get_all_card_effect_scenes():
		var card_effect: CardEffect = card_effect_scene.instantiate()
		var card_effect_name: String = card_effect.get_effect_name()
		var effect_item_button: EffectItemButton = load("res://Scenes/EffectItemButton.tscn").instantiate()
		effect_item_button.set_effect_name(card_effect_name)
		effects_vbox_container.add_child(effect_item_button)
