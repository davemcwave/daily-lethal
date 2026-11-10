# What's new: the Card Lab update

Everything that changed on the `modular-content` branch, written from a player's point of
view. The biggest piece is the **Card Lab**, where you build your own cards. Many of the
other changes make cards play the same way every time and make it easier to see what a card
will do before you play it.

**Every released puzzle still wins with its known solution.** A few older puzzles had their
enemy HP (and one its hand) adjusted so their solutions still finish exactly at 0 under the
new rules; see *Puzzles rebalanced* below. The 20 puzzles with no known solution weren't
checked, the same as before this update.

---

## The Card Lab

A card builder inside the game.

**Where to find it**
- On desktop: the **Card Lab** button on the main menu.
- On the web: **playlethal.fun/card-lab** opens straight into it. **Main menu** there takes
  you back to the website.

**Making a card**
- Set the name, energy cost, color (or two colors blended, like Haunt), icon and description.
- Pick the **icon** from a grid of every built-in card's picture, shown on your card's color.
- Add **effects** from about 45 building blocks: deal damage, draw, heal, gain energy, give
  yourself a buff (Sharp, Repeat, Regen…), inflict Burn or Vulnerable, create cards, and more.
  These are the same pieces the built-in cards are made of.
- Some effects hold other effects:
  - **"If ..., then ..."**: an effect that only happens when a condition is met.
  - **"Pick 1"**: you choose one of several effects when you play the card, like Potion.
- The description can show a setting's **live value** (the **{ }** button). If you change
  "Deal 3 damage" to 5, the text follows.
- Long names and descriptions **shrink to fit** the card instead of spilling out.

**Several cards at once**
- Keep up to **10 custom cards**. Switch between them with the name chips above the preview.
- **+ Card** adds one. **×**, or right-click a name and choose **Delete**, removes one.

**Test hand**
- Set Player HP, Player energy and Enemy HP.
- The hand is shown as real cards. Click **+ Add card** to add more copies of your cards or
  any built-in card. Drag a card to **reorder** the hand. Hover a card and click **×** to
  remove it.
- **Play test** opens a practice puzzle against a Training Dummy with exactly that hand, in
  that order. **Back to Card Lab** brings you back with everything as you left it.

**Saved automatically**
- Your cards and test hand are saved on your device as you work. They're there the next time
  you open the game. On the web, they're saved in your browser.

**Sharing with share codes**
- **Share code** copies one line of text (it starts with `LETHAL2-`). It holds your cards,
  your test hand and its order. Paste it anywhere: Discord, a chat, a forum.
- **Import code** opens a box where you paste a code, with two choices:
  - **Add to my cards** puts the shared cards next to yours and keeps your own cards and test
    settings.
  - **Replace all** swaps everything for what was shared.
- No account or server is needed. Codes only ever use the game's own pieces, so a shared
  code can't contain anything harmful.

---

## How cards play (now the same for every card)

Every card now plays in the same five steps:

1. **Pay** its energy cost.
2. **Effects** happen, top to bottom.
3. **Your statuses** react (Sharp, Repeat, …).
4. **Enemy statuses** react (Burn, …).
5. The card is **discarded**, then the game checks whether the enemy is dead.

Each step finishes before the next starts. Chains of reactions (Retaliate, Burn, Vulnerable,
Splinter pieces) now resolve one at a time, in order, instead of overlapping.

**New statuses wait a card.** As in Slay the Spire, a status gained during a card's play
starts working with the *next* card:
- The Sharp from Sharpen isn't used up by Sharpen itself.
- Echo's Repeat doesn't repeat Echo.
- Burn from Scorch, or from a custom card, doesn't burn on the card that inflicted it.
- A buff a card puts on the enemy also waits.
- Adding more to a status that's already there counts right away: Scorch on an enemy that
  already has Burn burns with Scorch's stacks included. Several released puzzles are built
  around that.

**Cards that now play like every other card:** Acuminate, Capacitor, Fragment, Sharpen and
Scorch. They used to have their own slightly different order.

**Cards that keep their own order on purpose:**
- Heartbeat, Mend and Potion pay their cost *after* their effects, so Heartbeat deals your HP
  from before paying.
- Scrap and Waste go to the discard pile *before* their effects.
- Tribute has one extra step after it's discarded.

**An attack's damage is always worked out in the same order:**
1. Base damage (the Rage card raises it)
2. Add (Sharp)
3. Multiply (Critical)
4. Split (Splinter)
5. Convert (Charge, Flame, Poison)
6. Deal damage: each hit gets +1 per Vulnerable
7. Reactions (Lifesteal, Retaliate)

Two statuses of the same kind go in the order you gained them. The full picture is at
**playlethal.fun/card-resolutions**.

**"Your next attack" means your next attack card.** As in Slay the Spire, statuses for your
next attack (Critical, Charge, Flame, Poison, Splinter, Lifesteal) apply to *every hit* of that
card and are used up once. Flurry with Critical deals double damage on all 3 strikes, and with
2 Poisons, one Flurry uses only one of them. A card replayed by Echo or Reverberate counts as
a new attack.

---

## Seeing what a card will do

- **Live damage numbers:** while you hold an attack over the play area, the number on the
  card changes to the total it will actually deal, Vulnerable and Splinter included. It
  turns gold when something changes it.
- **"Deal 3 damage" in red:** on damage cards. When the attack will be converted, it changes
  to what it becomes: "Apply 3 Vulnerable" (Poison), "Apply 3 Burn" (Flame), "Gain 3 energy"
  (Charge).
- **Show the math:** turn on **Options → Show Damage Math** to see, beside a held attack, how
  its damage is worked out, one step per line.
- **Statuses light up:** every status box (yours and the enemy's) that will react to the card
  pulses while you hold it over the play area.
- **"(Deals N damage)":** cards whose damage comes from a count (Heartbeat from your HP,
  Thunderbolt from your energy, Shovel from your discard pile, Balance) show the current
  amount right on the card.
- **Status descriptions on hover:** hover any buff or debuff box to read it. Tapping still
  works on mobile.
- **Status text shows the real number:** "Your next 2 attacks deal double damage" instead of
  "X".
- **One box per status kind:** two Criticals show as one "Critical 2" box. They still each
  act separately, as before.

---

## Statuses and cards that work better

- **Vulnerable** is one box that stacks ("Vulnerable 3"). Each stack adds 1 to every hit the
  enemy takes: each Splinter piece, each Burn tick. Pound 4 against Vulnerable 2 hits for 6.
- **The enemy's statuses** are all in one column on the right, like yours, and every status
  box is the same size and text style.
- **Lifesteal** heals everything the attack did, Vulnerable and every Splinter piece included.
  An attack that was converted (Charge, Flame, Poison) doesn't use it up.
- **Corrode** now trashes the attack that hit the enemy. Before, it could trash the card
  played *before* the attack.
- **Copy, Return and Trash** only act on cards you play, as they leave play. Cards discarded
  by an effect (Scrap, Armory…) no longer set them off.
- **Hand choices** (Scrap's "discard a card", and so on) no longer offer the card you're
  playing.
- **Rage and similar permanent damage bonuses** now also work on Heartbeat, Thunderbolt,
  Shovel and Balance.
- **Sharp and Splinter** no longer show an infinity sign. They count down.
- **Retaliate** lights up when you hold an attack, since attacking will set it off.
- **"Pick 1" choices:** every option now has a label ("Draw 1", "Gain Sharp 2",
  "Inflict 3 Burn") in a proper color. Options used to show up as empty black boxes.
- Fixed a rare freeze with Repeat and cards that sometimes skip their choice (Gambit).
- Fixed some symbols that showed as a box on mobile (an arrow and the heart/energy icons in
  the tutorial).
- Fixed a card you drag over the play area while the previous card is still playing: it can
  now be dropped as soon as that card finishes.
- The Card Lab is only offered on a computer; on phones and tablets it explains why.

---

## Puzzles rebalanced

The new rules changed how some older solutions play out. Each puzzle below still wins with
its known solution, now finishing the enemy at exactly 0:

| Puzzle | Change |
|---|---|
| Serpents | Enemy HP 49 → 22 |
| Blue Dragon | Enemy HP 91 → 51 |
| Backstreet Thug | A third Flurry, 5 energy, enemy HP 33 → 69 |
| Fuchsia Dragon | Enemy HP 105 → 57 |
| Wasp Swarm | Enemy HP 90 → 126 |
| Termites | Enemy HP 90 → 126 |
| Barbarian | Enemy HP 42 → 46 |
| Viking | Enemy HP 12 → 13 |
| Swordmaster | Enemy HP 12 → 15 |
| Circuit Breaker | Enemy HP 48 → 52 |
| Angel of Revelation | Enemy HP 400 → 407 |
| Gargoyle | Enemy HP 18 → 32 |

---

## Behind the scenes

Players won't see this part directly, but it's why the update is safe:

- **Automatic testing:** every released puzzle is replayed with its known solution. Every
  effect is tried on its own. Every card is played after every other card (3,600 pairs).
  The whole suite passes.
- **Cards as data:** cards are built from simple data. Built-in cards and Card Lab cards are
  made the same way, which is what makes custom cards possible.

---

*Not yet checked by hand:*
- *Pasting a code into **Import code** in the web version. Browsers limit clipboard access.*
- *A custom card that puts a buff on the enemy. The rule is the same one used for Burn, which
  was checked in game, but this case wasn't watched directly.*
