extends VBoxContainer

func add_debuff(debuff: Debuff) -> void:
	var debuff_panel: Panel = load("res://Scenes/DebuffPanel.scn").instantiate()
	debuff_panel.set_text(debuff.get_debuff_name())
	debuff_panel.set_debuff(debuff)
	add_child(debuff_panel)

func get_debuffs() -> Array[Debuff]:
	var debuffs: Array[Debuff] = []
	for debuff_panel: DebuffPanel in get_children():
		debuffs.append(debuff_panel.get_debuff())
	return debuffs
