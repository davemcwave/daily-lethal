extends Debuff
class_name BurnDebuff

# Burn X: each card played deals X damage to the enemy and reduces stacks by 1.
# Stacks merge when multiple applications are applied.

@export var burn_count: int = 1

func _ready() -> void:
	activation_type = ActivationType.OnCardPlay
	unlimited_uses = false
	super._ready()

func get_debuff_name() -> String:
	return "Burn %d" % burn_count

func set_stacks(n: int) -> void:
	burn_count = n

func add_stacks(amount: int) -> void:
	burn_count += amount
	if is_instance_valid(debuff_panel):
		debuff_panel.update_text()

func can_merge_with(other_debuff: Debuff) -> bool:
	return other_debuff is BurnDebuff

func merge_with(other_debuff: Debuff) -> void:
	if other_debuff is BurnDebuff:
		add_stacks(other_debuff.burn_count)

func activate() -> void:
	target.hurt(burn_count, true)
	burn_count -= 1
	if is_instance_valid(debuff_panel):
		await debuff_panel.blink()
	if not is_instance_valid(debuff_panel):
		return
	if burn_count <= 0:
		debuff_panel.queue_free()
		queue_free()
	else:
		debuff_panel.update_text()
