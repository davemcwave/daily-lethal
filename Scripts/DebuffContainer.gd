extends VBoxContainer

func add_debuff(debuff: Debuff) -> void:
	var debuff_panel: Panel = load("res://Scenes/DebuffPanel.scn").instantiate()
	debuff_panel.set_text(debuff.get_debuff_name())
	add_child(debuff_panel)
