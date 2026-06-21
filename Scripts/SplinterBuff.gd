extends Buff
class_name SplinterBuff

# Stacking counter. Each stack = one future damage instance that gets split into
# 1-damage hits ("deal 1 damage that many times instead of one big hit"). Each
# attack consumes ONE stack; the count does NOT scale the damage — a hit of N is
# always N hits of 1, regardless of how many stacks remain.
#
# uses_amount is the stack count, but we manage it OURSELVES (unlimited_uses = true
# so the base class / BuffsContainer don't also decrement or free it). This is
# required for correctness under concurrency: multi-strike cards like Flurry fire
# their strikes WITHOUT awaiting, so several strikes resolve interleaved in one
# frame. We must consume a stack synchronously (before the first await) so a burst
# of strikes can only splinter as many times as we have stacks — otherwise every
# strike in the burst sees the stack as still available and splinters.
# Grant N stacks from a card by setting uses_amount via buff_params, e.g.
# { "uses_amount": 2 }.

func _init() -> void:
	# Set at instantiation so add_buff() sees these BEFORE the buff enters the tree
	# (merge + unlimited_uses are read at add time, before _ready runs).
	merge_buff_panels = true
	unlimited_uses = true
	activation_type = Buff.ActivationType.OnAttack
	priority = 2

func _ready() -> void:
	# Re-assert in case the buff scene stored different values. Splinter MUST fire on
	# OnAttack — the only phase that runs before DamageCardEffect checks
	# context['deal_damage']. Any later (OnHit / OnDealDamage) and the original hit
	# already landed, so the 1-damage hits stack on top instead of replacing it.
	# priority = 2 fires it AFTER damage modifiers (Sharp / Critical, priority 0) and
	# other replacement buffs (Poison / Charge, priority 1). unlimited_uses keeps the
	# base class from decrementing/freeing — we own uses_amount (see activate()).
	activation_type = Buff.ActivationType.OnAttack
	priority = 2
	unlimited_uses = true

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
	# Already spent. Guards against concurrent over-triggering: Flurry (and any card
	# that fires multiple strikes without awaiting) resolves several strikes in the
	# same frame. Because we consume the stack synchronously below — before the first
	# await — later strikes in that burst reach here with uses_amount == 0 and skip,
	# so Splinter only ever transforms ONE strike per stack.
	if uses_amount <= 0:
		return true

	# A higher-priority replacement buff (Poison, Charge, ...) already converted this
	# attack to a non-damage effect — nothing to split. Keep the stack for an attack
	# that actually deals damage.
	if not context.get('deal_damage', true):
		return true

	# Consume the stack NOW, before any await, so concurrent strikes can't all see it
	# as available.
	uses_amount -= 1
	if is_instance_valid(buff_panel):
		buff_panel.update_text()

	# Replace this single hit with `current_damage_amount` hits of 1.
	var current_damage_amount: int = context['current_damage_amount']
	context['deal_damage'] = false

	var target_to_hit: Node = get_other_target()
	for i in range(current_damage_amount):
		target_to_hit.hurt(1)
		await get_tree().create_timer(0.07).timeout

	# We own removal (unlimited_uses, so the container won't free us).
	if uses_amount <= 0 and is_instance_valid(buff_panel):
		buff_panel.queue_free()

	return true
