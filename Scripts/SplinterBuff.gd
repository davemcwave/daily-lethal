extends Buff
class_name SplinterBuff

# Stacking counter. Each stack = one future damage instance that gets split into
# 1-damage hits ("deal 1 damage that many times instead of one big hit"). Each
# attack consumes ONE stack; the count does NOT scale the damage — a hit of N is
# always N hits of 1, regardless of how many stacks remain.
#
# The stack count IS the base `uses_amount`: the engine already decrements it each
# activation and BuffsContainer frees the panel at 0, so there's no separate
# counter and no `unlimited_uses` here. Grant N stacks from a card by setting
# uses_amount via buff_params, e.g. { "uses_amount": 2 }.

func _init() -> void:
	# Set at instantiation so add_buff() sees merge enabled BEFORE the buff enters
	# the tree (merge is decided at add time, before _ready runs).
	merge_buff_panels = true
	activation_type = Buff.ActivationType.OnAttack
	priority = 2

func _ready() -> void:
	# Re-assert the activation hook in case the buff scene stored a different value.
	# Splinter MUST fire on OnAttack — the only phase that runs before
	# DamageCardEffect checks `context['deal_damage']`. Any later (OnHit /
	# OnDealDamage) and the original hit already landed, so the 1-damage hits stack
	# on top instead of replacing it. priority = 2 fires it AFTER damage modifiers
	# (Sharp / Critical, priority 0) AND other replacement buffs (Poison / Charge,
	# priority 1), so it splits the FINAL amount and yields to attacks already
	# converted to a non-damage effect (see the guard in activate()).
	activation_type = Buff.ActivationType.OnAttack
	priority = 2

func get_buff_name() -> String:
	return buff_name + " " + str(uses_amount)

func can_merge_with(other_buff: Buff) -> bool:
	return other_buff is SplinterBuff

func merge_with(other_buff: Buff) -> void:
	if other_buff is SplinterBuff:
		uses_amount += other_buff.uses_amount
		if is_instance_valid(buff_panel):
			buff_panel.update_text()

func activate(context: Dictionary = {}) -> bool:
	# If a higher-priority replacement buff (Poison, Charge, ...) already converted
	# this attack into a non-damage effect, there is no damage left to split. Do
	# nothing and KEEP the stack for an attack that actually deals damage — don't
	# call super.activate(), so uses_amount isn't spent and the panel survives.
	if not context.get('deal_damage', true):
		return true

	var current_damage_amount: int = context['current_damage_amount']

	# Replace this single hit with `current_damage_amount` hits of 1. The base
	# activate() below spends a stack (uses_amount -= 1) and BuffsContainer frees the
	# panel once it reaches 0; remaining stacks split future attacks.
	context['deal_damage'] = false

	var target_to_hit: Node = get_other_target()
	for i in range(current_damage_amount):
		target_to_hit.hurt(1)
		await get_tree().create_timer(0.07).timeout

	var result: bool = super.activate(context)

	# Refresh the "Splinter N" label while stacks remain (the panel is freed by the
	# container on the activation that brings uses_amount to 0).
	if uses_amount > 0 and is_instance_valid(buff_panel):
		buff_panel.update_text()

	return result
