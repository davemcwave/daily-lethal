extends Panel
class_name CardEditorCardPreviewPanel

@onready var title_label: RichTextLabel = $CardPreview/TitlePanel/Title
@onready var icon_texture: TextureRect = $CardPreview/IconPanel/Icon
@onready var description_label: RichTextLabel = $CardPreview/DescriptionPanel/Title
@onready var energy_label: RichTextLabel = $CardPreview/EnergyPanel/Energy
@onready var gradient_background: TextureRect = $CardPreview/IconPanel/GradientBackground
@onready var icon_panel: Panel = $CardPreview/IconPanel

func set_title(new_title: String) -> void:
	title_label.set_text(new_title)
	
func set_icon_texture(new_texture: Texture2D) -> void:
	icon_texture.set_texture(new_texture)
	
func set_description(new_description: String) -> void:
	description_label.set_text(new_description)
	
func set_energy(new_energy: String) -> void:
	energy_label.set_text(new_energy)
	
func display_card_info(card: Card) -> void:
	set_title(card.get_card_name())
	set_icon_texture(card.get_icon_texture())
	set_description(card.get_card_description())
	set_energy(str(card.get_energy_cost()))
	
	if card.has_gradient_background():
		gradient_background.set_texture(card.get_gradient_background_texture())
		gradient_background.show()
	else:
		icon_panel.get("theme_override_styles/panel").bg_color = card.get_background_color()
		gradient_background.hide()
	
