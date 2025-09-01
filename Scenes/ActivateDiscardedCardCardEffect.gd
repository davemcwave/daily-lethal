extends ActivateCardCardEffect

@export_enum ("Top", "Bottom") var card_direction: String = "Top"
@onready var discard_panel: DiscardPanel = scene.get_node("DiscardPanel")

func apply():
	#await discard_panel.updated
	
	match card_direction:
		"Top":
			set_card(discard_panel.get_first_card())
		"Bottom":
			set_card(discard_panel.get_last_card())

	super.apply()
