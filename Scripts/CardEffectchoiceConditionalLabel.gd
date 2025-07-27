extends RichTextLabel
class_name CardEffectChoiceConditionLabel

enum ConditionalType {
	Or,
	And
}

@export var conditional_type = ConditionalType.Or

func _ready():
	update_text()
	
func update_text() -> void:
	var inside_text = ""
	match conditional_type:
		ConditionalType.Or:
			inside_text = "OR"
		ConditionalType.And:
			inside_text = "AND"
		_:
			inside_text = "OR"
	set_text("[shake rate=2.0 level=3 connected=1][center][b]%s[/b][/center][/shake]" % inside_text)
