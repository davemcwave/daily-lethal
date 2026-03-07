# Card Play Order

## Standard Order

Every card plays in this order:

| # | What happens | Notes |
|---|---|---|
| 1 | **Player places card in play area** | |
| 2 | **Cost is paid** | Blood and Discount buffs activate here, at the moment of payment — not during the "on play" phase |
| 3 | **Card effects activate** | Damage, applying buffs/debuffs, healing, etc. |
| 4 | **Player status effects activate** *(on play)* | e.g. Sharp, Echo — any player buff marked as "on card play" |
| 5 | **Enemy status effects activate** *(on play)* | e.g. Burn — any enemy debuff marked as "on card play" |
| 6 | **Card is discarded** | |

---

## Exceptions

### (3) before (2) — Card effects activate before the cost is paid
Heartbeat, Mend, Potion, Revive

---

### (4) and (5) before (3) — On-play status effects fire before card effects
Capacitor, Sharpen, Cauterize, Hunger

---

### (6) before (3) — Card is discarded before its effects activate
Armory, Cauterize, Hunger

---

### (4) is skipped — Player on-play status effects don't fire at all
Cleanse

---

### (4) fires but skips one buff — Echo skips its own buff
Echo applies a buff to the player as its card effect, but intentionally does not fire that same buff during the on-play phase of the same play.

---

### (5) fires but skips one debuff — Scorch skips its own Burn
Scorch applies Burn to the enemy as its card effect, but intentionally does not fire that newly-applied Burn during the on-play phase of the same play. Pre-existing Burn still fires.

---

### Extra step after (6) — Cleanup runs after the card is discarded
Scrap, Tribute

---
