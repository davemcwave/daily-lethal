extends Buff
class_name LifestealBuff
## "The next time you deal damage, heal HP equal to the damage dealt."
## Fires after the attack lands (React) and heals everything the enemy lost
## from it: the hit, Vulnerable's splash, every Splinter piece. An attack that
## dealt nothing (converted by Charge / Flame / Poison) doesn't reach here, so
## Lifesteal waits for a real hit.

func activate(context: Dictionary = {}) -> bool:
	var damage_dealt: int = int(context.get('damage_dealt', context.get('current_damage_amount', 0)))
	if damage_dealt <= 0:
		return true  # nothing landed: keep Lifesteal
	target.add_health(damage_dealt)
	return super.activate()

func preview_react(context: Dictionary) -> Dictionary:
	var dealt: int = context.get("damage_dealt", 0)
	return {"op": "after", "text": "heal %d" % dealt, "name": "lifesteal"} if dealt > 0 else {}
