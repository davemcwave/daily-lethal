# Card Play Order

## Every card

1. **Pay** its energy cost.
2. **Effects** happen, top to bottom.
3. **Your statuses** react to the play (Sharp, Repeat, …).
4. **Enemy statuses** react to the play (Burn, …).
5. **Discard**, then the game checks whether the enemy is dead.

Each step finishes before the next starts.

## Rules

- **New statuses wait a card.** A status gained during a play doesn't react to that play: your buffs, buffs put on the enemy, and statuses a card's Debuff effect puts on the enemy (Scorch's Burn, a custom card's Burn). Stacks added to a status already there don't change it.
- **The card being played is in play.** It's in neither your hand nor your discard pile until its play ends.
- **"Last card played"** is the card from the moment it's played.
- **Copy, Return and Trash** only act on cards you played, when they leave play. A card trashed mid-play is trashed when its play ends.
- **Damage reactions** (Retaliate, Burn, Vulnerable, Splinter hits) resolve one at a time, in order.
- **Attack order:** base → add (Sharp) → multiply (Critical) → split (Splinter) → convert (Charge, Flame, Poison) → deal damage (each hit +1 per Vulnerable) → reactions (Lifesteal, Retaliate). Same kind: first gained goes first.

## Exceptions

| Cards | Order |
|---|---|
| Heartbeat, Mend, Potion | Effects → **Pay** → statuses → discard (`pay_cost_after_effects`) |
| Scrap, Waste | Pay → **Discard** → effects → statuses |
| Tribute | Normal, plus one more step after it's discarded |

Stacks added to a status that's already there count right away: Scorch after Flame's Burn (Forge) ticks with Scorch's stacks included on Scorch's own play. Released puzzles depend on that (Fire Mage, Lover, Popped Corn, ...).
