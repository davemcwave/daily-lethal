extends Panel
class_name EditCardPanel

@onready var tab_container: TabContainer = $TabContainer
@onready var card_tab: Panel = tab_container.get_node("Card")
@onready var card_name_input: LineEdit = card_tab.get_node("CardNameInput")
@onready var card_cost_input: LineEdit = card_tab.get_node("CardCostInput")
@onready var card_description_input: TextEdit = card_tab.get_node("CardDescriptionInput")
@onready var effects_tab: Panel = tab_container.get_node("Effects")
@onready var card_color_buttons: Control = $TabContainer/Card/CardColorButtons
@onready var card_icon_upload_button: Button = $TabContainer/Card/CardIconUploadButton

func display_card_info(card: Card) -> void:
	card_name_input.set_text(card.get_card_name())
	card_cost_input.set_text(str(card.get_energy_cost()))
	card_description_input.set_text(card.get_card_description_without_bb_code())
	
	var is_permanent_card: bool = card.is_permanent_card()
	card_name_input.set_editable(not is_permanent_card)
	card_cost_input.set_editable(not is_permanent_card)
	card_description_input.set_editable(not is_permanent_card)
	enable_color_buttons(not is_permanent_card)
	enable_icon_upload(not is_permanent_card)

func enable_color_buttons(enabled: bool) -> void:
	for color_button: Button in card_color_buttons.get_children():
		color_button.set_disabled(not enabled)
		
func enable_icon_upload(enabled: bool) -> void:
	card_icon_upload_button.set_disabled(not enabled)
