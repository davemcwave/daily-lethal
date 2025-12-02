extends Button

const NO_ITEM_CHOSEN = -1

@onready var option_button: OptionButton = $OptionButton
@onready var background = $"/root/Background"

func _ready() -> void:
	populate_options()
	
func populate_options() -> void:
	var card_effect_scenes: Array[Resource] = background.get_all_card_effect_scenes()
	for card_effect_scene in card_effect_scenes:
		var card_effect = card_effect_scene.instantiate()
		
		if not (card_effect is CardEffect) or card_effect.get_effect_name() == "":
			continue
			
		option_button.add_item(card_effect.get_effect_name())

func disappear() -> void:
	self_modulate.a = 0.0
	$Title.modulate.a = 0.0
	
func appear() -> void:
	self_modulate.a = 1.0
	$Title.modulate.a = 1.0
	
func add_card_effect_panel(card_effect_panel) -> void:
	disappear()
	add_child(card_effect_panel)
	
func _on_pressed():
	option_button.show()
	disappear()
	#var card_effect_buttons_container = load("res://Scenes/CardEffectButtonsContainer.scn").instantiate()
	#var index = get_index()
	#get_parent().add_child(card_effect_buttons_container)
	#get_parent().move_child(card_effect_buttons_container, index)
	#queue_free()

func close_option_button() -> void:
	option_button.hide()
	#option_button.selected = NO_ITEM_CHOSEN

func _on_option_button_item_selected(index):
	var card_effect_name: String = option_button.get_item_text(index)
	match card_effect_name:
		"None":
			close_option_button()
			appear()
		_:
			var card_effect: CardEffect = background.get_card_effect_by_name(card_effect_name) 
			if card_effect != null:
				add_card_effect_panel(card_effect.get_card_effect_panel())
func _on_option_button_focus_exited():
	close_option_button()
