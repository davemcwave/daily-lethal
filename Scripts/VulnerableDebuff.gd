extends Debuff
class_name VulnerableDebuff
## "Whenever this target takes damage, they take an additional X damage."
## One box, "Vulnerable N": applying more adds stacks (like Burn). The attack order's
## Deal damage step: each stack adds 1 to every hit the enemy takes (each Splinter
## piece, each Burn tick), as part of that hit's number (Enemy.hurt adds it).
## Converted attacks (Charge, Flame, Poison) deal no hits, so they don't get it.

@export var stacks: int = 1

func get_debuff_name() -> String:
	return "Vulnerable %d" % stacks

func set_stacks(n: int) -> void:
	stacks = maxi(n, 1)

func can_merge_with(other_debuff: Debuff) -> bool:
	return other_debuff is VulnerableDebuff

func merge_with(other_debuff: Debuff) -> void:
	if other_debuff is VulnerableDebuff:
		stacks += other_debuff.stacks
		if is_instance_valid(debuff_panel):
			debuff_panel.update_text()

## What it adds to each hit.
func get_incoming_damage_bonus() -> int:
	return stacks

func activate() -> void:
	# The bonus is already in the hit (Enemy.hurt); one blink shows it applied.
	if is_instance_valid(debuff_panel):
		debuff_panel.blink()

## X in the text: stacks.
func get_description_number() -> int:
	return stacks
