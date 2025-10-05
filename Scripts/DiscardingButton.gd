extends Button
class_name ChoosingButton

func show_good_icon() -> void:
	$GoodIcon.show()
	$BadIcon.hide()
	$NeutralIcon.hide()
	
func show_bad_icon() -> void:
	$BadIcon.show()
	$GoodIcon.hide()
	$NeutralIcon.hide()
	
func show_neutral_icon() -> void:
	$NeutralIcon.show()
	$BadIcon.hide()
	$GoodIcon.hide()
	
func set_icon(choose_type) -> void:
	match choose_type:
		CardsChooseArea.ChooseType.Good:
			show_good_icon()
		CardsChooseArea.ChooseType.Bad:
			show_bad_icon()
		CardsChooseArea.ChooseType.Neutral:
			show_neutral_icon()
