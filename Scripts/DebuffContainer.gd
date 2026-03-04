extends Control

func add_debuff(debuff: Debuff) -> void:
	if _try_merge_existing_debuff(debuff):
		return
	var debuff_panel: Panel = load("res://Scenes/DebuffPanel.scn").instantiate()
	debuff_panel.set_text(debuff.get_debuff_name())
	debuff_panel.set_debuff(debuff)
	add_child(debuff_panel)

func _try_merge_existing_debuff(new_debuff: Debuff) -> bool:
	for debuff_panel: DebuffPanel in get_children():
		var existing: Debuff = debuff_panel.get_debuff()
		if is_instance_valid(existing) and existing.can_merge_with(new_debuff):
			existing.merge_with(new_debuff)
			return true
	return false

func get_debuffs() -> Array[Debuff]:
	var debuffs: Array[Debuff] = []
	for debuff_panel: DebuffPanel in get_children():
		debuffs.append(debuff_panel.get_debuff())
	return debuffs
