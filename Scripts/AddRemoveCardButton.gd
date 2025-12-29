extends Button
class_name AddRemoveCardButton

@onready var background = $"/root/Background"
@onready var option_button: OptionButton = $OptionButton
@onready var card_preview: Panel = $CardPreview

func _ready() -> void:
	#card_preview.set("theme_override_styles/panel", card_preview.get("theme_override_styles/panel").duplicate(DUPLICATE_USE_INSTANTIATION))
	
	populate_options()
	
	option_button.connect("item_focused", self._on_option_button_item_focused)
	
func populate_options() -> void:
	var card_scenes: Array[Resource] = background.get_all_card_scenes()
	for card_scene in card_scenes:
		var card = card_scene.instantiate()
		
		if not (card is Card) or card.get_card_name() == "":
			continue
			
		option_button.add_item(card.get_card_name())

func _on_pressed():
	option_button.show()
	option_button.show_popup()

func _on_option_button_item_selected(index):
	var card_name: String = option_button.get_item_text(index)
	
	if card_name == "None":
		card_preview.hide()
		set_text("+")
	else:
		var card = load("res://Scenes/%sCard.scn" % card_name).instantiate()
		card_preview.set_card(card)
		card_preview.show()
		set_text("")
		
	option_button.hide()
	
func _on_option_button_item_focused(index):
	print(option_button.get_item_text(index))
	
