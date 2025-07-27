extends Button
class_name CardEffectChoiceButton
var card_effect: CardEffect = null
func set_button_text(new_text: String) -> void:
	$RichTextLabel.set_text("[shake rate=10.0 level=3 connected=1][center][b]%s[/b][/center][/shake]" % new_text)

func set_color(new_color: Color) -> void:
	get("theme_override_styles/normal").bg_color = new_color

func set_card_effect(new_card_effect: CardEffect) -> void:
	card_effect = new_card_effect
	
func get_card_effect() -> CardEffect:
	return card_effect
