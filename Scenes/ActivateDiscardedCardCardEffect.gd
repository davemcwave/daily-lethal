extends ActivateCardCardEffect

@export_enum ("Top", "Bottom") var card_direction: String = "Top"
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

func apply() -> bool:
	
	match card_direction:
		"Top":
			if discard_panel.get_last_card() != null:
				set_card(discard_panel.get_last_card())
		"Bottom":
			if discard_panel.get_first_card() != null:
				set_card(discard_panel.get_first_card())

	return await super.apply()
