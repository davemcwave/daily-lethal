extends Card

const TRASH_CARD_EFFECT_SCRIPT := preload("res://Scripts/TrashCardEffect.gd")

var pending_trash_effects: Array[CardEffect] = []
var can_run_pending_trash_effects: bool = true

func play():
	begin_play_resolution()
	handle_sfx()
	buffs_container.clear_buffs_added_or_removed_this_turn()
	scene.increment_card_count()
	scene.add_card_played(self)
	set_state(State.Playing)
	pay_cost(energy_cost)
	await apply_card_effects()
	scene.set_last_card_effects(self)
	await buffs_container.activate_buffs(Buff.ActivationType.OnCardPlay)
	await enemy.activate_on_card_play_debuffs()
	await discard()
	await _apply_pending_trash_effects()
	scene.check_game_over()
	finish_play_resolution()

func apply_card_effects() -> bool:
	pending_trash_effects.clear()
	can_run_pending_trash_effects = true
	for card_effect in card_effects:
		if card_effect is TrashCardEffect:
			pending_trash_effects.append(card_effect)
			continue
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		var card_effect_result = await card_effect.apply()
		if break_effects_on_apply and card_effect_result == false:
			can_run_pending_trash_effects = false
			break
	if queue_free_after_applying_card_effects:
		queue_free()
	return true

func _apply_pending_trash_effects() -> void:
	if not can_run_pending_trash_effects:
		pending_trash_effects.clear()
		return
	for trash_effect in pending_trash_effects:
		if card_effect_delay > 0.0:
			await get_tree().create_timer(card_effect_delay).timeout
		await trash_effect.apply()
	pending_trash_effects.clear()
	
