# Changes from master (for players)

Every player-visible difference between the current release (`master`) and this branch, worked
out from the code, not from earlier changelogs. Written for players, with examples. Cut what
they don't need.

Platforms: **Windows** = the downloadable desktop game. **Web** = playlethal.fun (desktop and
phone layouts). If a change doesn't name a platform, it applies everywhere.

---

## 1. Gameplay

### "Your next attack" statuses cover the whole attack card
- **Before:** each hit of a multi-hit card used up its own status. Flurry with one Critical
  doubled only the first strike (2 + 1 + 1 = 4). Venom's 2 Poison converted Flurry's first two
  strikes, and the third dealt damage.
- **Now:** the status applies to every hit of the card and is used up once. Flurry with
  Critical deals 2 + 2 + 2 = 6. With 2 Poison, all 3 strikes convert and the second Poison
  stays for your next attack.
- Applies to Critical, Charge, Flame, Poison, Splinter and Lifesteal.
- A card played again by Repeat, or by Reverberate, counts as a new attack.

### Attacks follow one fixed order
Every attack now works out its damage in the same order. Before, statuses mostly went in the
order you got them, and some only acted when damage actually landed.

1. Base damage
2. **Add:** Sharp
3. **Multiply:** Critical
4. **Split:** Splinter
5. **Convert:** Charge, Flame, Poison
6. **Deal damage:** each hit gets +1 per Vulnerable
7. **React:** Lifesteal, Retaliate, Corrode

What that changes:
- **Sharp always adds before a conversion.** Before: Capacitor, then Sharpen (3), then Slash (2)
  converted only 2, wasting Sharp. Now it converts 5.
- **Critical doubles converted and split attacks.** Before, Critical was skipped when Charge,
  Poison or Flame converted the attack or Splinter split it. Now Target, Capacitor, Slash gains
  4 energy (was 2, with Critical kept). With Venom: double Vulnerable. With Forge: double Burn.
  With Splinter: double the pieces.
- **Splinter is used up when the attack is converted**, and the converted amount includes every
  piece. Before, a conversion left Splinter unused.
- **Lifesteal heals what the attack really dealt**, after it lands: Vulnerable, every Splinter
  piece and Critical included. Before, it missed Vulnerable, only counted Critical if you got it
  first, and never triggered on Splinter attacks. Example: Hunger, Wound, Slash (2) heals 3
  (was 2).
- **Corrode (enemy status) trashes the attack that hit it**, once, when that card finishes.
  Before, it also reacted to Burn ticks and Splinter pieces, and trashed the last card played,
  which wasn't always the attack.
- **Retaliate (Bloodthorn) hits back once per attack.** Before, each Splinter piece and Burn tick
  set it off. Bloodthorn's own cards don't use Splinter or Burn, so the puzzle plays the same.

### Vulnerable is one box
- Same damage as before: each stack adds 1 to every hit, including Splinter pieces and Burn
  ticks.
- It now shows as a single "Vulnerable N" box, and the extra damage lands with the hit instead
  of as a separate hit a moment later.

### Splinter isn't wasted on a 0-damage attack
- Before, a 0-damage attack used a Splinter stack and did nothing. Now Splinter waits for an
  attack that does damage.

### Copy, Trash and Return only act on cards you play
- **Before:** any card going to the discard pile set them off, including cards an effect
  discarded. With two Trash statuses (Haunt and Tribute), Scrap's discard could waste the second
  Trash.
- **Now:** only the card you played sets them off. The second Trash or Copy waits for your next
  card.

### Fixes
- **Trash on Scrap, Armory, Hunger, Cauterize or Trace:** the card could be removed while it was
  still playing (Scrap's discard choice or Armory's pick screen still open), leaving the play
  area locked. Fixed: the trash happens when the card finishes.
- **Echo, then Gambit:** if Gambit had nothing to choose, the game froze. Fixed.
- **Echo, then Hunger:** Repeat replayed the card before Hunger instead of Hunger. Now it
  replays Hunger (a second Lifesteal).

### Puzzles changed
Enemy HP changed so each puzzle's known solution still wins under the new rules:

| Puzzle | Date | Change |
|---|---|---|
| Gargoyle | 2025-08-21 | Enemy HP 18 to 32 |
| Wasp Swarm | 2025-09-13 | Enemy HP 90 to 126 |
| Barbarian | 2025-10-03 | Enemy HP 42 to 46 |
| Serpents | 2025-10-27 | Enemy HP 49 to 22 |
| Blue Dragon | 2025-11-06 | Enemy HP 91 to 51 |
| Termites | 2025-12-03 | Enemy HP 90 to 126 |
| Swordmaster | 2026-02-17 | Enemy HP 12 to 15 |
| Circuit Breaker | 2026-02-19 | Enemy HP 48 to 52 |
| Viking | 2026-03-11 | Enemy HP 12 to 13 |
| Backstreet Thug | 2026-04-06 | A third Flurry, energy 4 to 5, enemy HP 33 to 69 |
| Fuchsia Dragon | 2026-08-21 | Enemy HP 105 to 57 |
| Angel of Revelation | 2026-08-28 | Enemy HP 400 to 407 |

---

## 2. The Library (new)

**Where:** Windows main menu > **Library**. Web: **playlethal.fun/library**.

### Puzzles tab
- Every released daily puzzle in one table: date, enemy, author, difficulty (skulls), enemy
  status, cards, HP, energy and enemy HP. Newer dailies are fetched online, so the list stays
  current.
- Click a column title to sort.
- **Search anything** matches any field.
- Filters: cards (pick any number; a puzzle must have all of them, and hovering a card name
  previews the card), difficulty, beaten or not, enemy status (none, Doom, Retaliate), author,
  and source (official or custom).
- Double-click or **PLAY** to play. The win screen's **Next Puzzle** plays the next puzzle in
  your current list.
- Beaten puzzles get a green tick, saved on your device.
- Your custom puzzles appear here too, marked **CUSTOM** in purple, with **Edit in Puzzle Lab**,
  **Share code** and **Delete** buttons.
- **Import code** (top right) adds cards and puzzles someone shared.

### Cards tab
- Every card used in a released puzzle, shown as it looks in your hand.
- Filters: search, cost, color (any number), the story world that introduces it, author
  (community designers, or mcwavegames for the originals), source (official or custom). Sort by
  name, cost, most used or story order.
- Click a card to see its text, an explanation of every effect and keyword on it, who made it,
  and **Puzzles with this card**, which opens the Puzzles tab filtered to that card.
- Your custom cards appear too, with a purple **CUSTOM** tag, plus **Edit in Puzzle Lab**,
  **Share code** and **Delete** (blocked while one of your puzzles uses the card).

---

## 3. The Puzzle Lab (new)

**Where:** Windows main menu > **Puzzle Lab**. Web: **playlethal.fun/puzzle-lab** (needs a
computer with a mouse; phones and tablets get a message instead).

### Custom Cards tab
- Up to 10 cards, each on its own tab (**×** on a tab deletes it after a second click; **+ New
  card** adds one).
- Set the name, energy cost, one or two colors, icon (any built-in card's picture) and
  description. Long text shrinks to fit the card.
- Add effects from about 45 building blocks, the same pieces the built-in cards are made of:
  damage, draw, heal, energy, give yourself a status, inflict Burn or Vulnerable, create cards,
  and more. Some hold other effects: "if ..., then ..." and "pick 1".
- The description can show a setting's live value, so "Deal 3 damage" follows the setting.
- **Pick to Create** can offer your own cards, not just built-in ones.

### Custom Puzzle tab
- Puzzle name, author, difficulty (1 to 5 skulls, or not set), player HP, player energy and
  enemy HP.
- The hand: your cards and any built-in card, in the order you set. Drag to reorder, **×** to
  remove. **Add card** lists your cards and the built-in ones; hover a name to preview the
  card. A puzzle can use just some of your cards.
- **Play test** plays the puzzle right away. **Back to Puzzle Lab** returns with everything as
  you left it.

### Saving and sharing
- Your work saves automatically on your device (in your browser on the web).
- **Save to Library** keeps your cards and puzzle in the Library. If a card or puzzle with the
  same name is already there, it asks before overwriting.
- **Go to Library** opens the Library.
- **Share code** (in the Library) copies one line of text to paste in Discord or anywhere. A
  puzzle's code includes only the cards it uses. **Import code** in the Library adds the cards
  only, or the cards and puzzles; same names ask before overwriting.
- No account or server. Codes only use the game's own pieces, so a shared code can't contain
  anything harmful.

---

## 4. Also changed

### Windows: starts at a main menu
- **Before:** the Windows game opened straight into the daily puzzle.
- **Now:** it opens a main menu: **Play** (larger), **Daily**, **Library**, **Puzzle Lab**, with
  Options and Discord as icons in the top right.
- **Daily** plays today's puzzle, or the latest one if today's isn't out yet.
- **Play** opens story mode, starting with the tutorial the first time. **Options > Replay
  Tutorial** shows it again. The tutorial's energy and heart symbols are now proper icons, and
  finishing it leads to the story map.

### Windows: story mode, rebuilt
- **Before:** one map of 47 puzzles, all playable from the start.
- **Now:** 21 named worlds in 13 tiers, 119 puzzles: 72 released puzzles and 47 new ones made
  for story mode.
  - Each world teaches a few cards. Its puzzles open one at a time, with a boss last.
  - A tier opens when every world before it is finished; paired worlds can be played in either
    order.
  - Hover a world to read its story, or a puzzle to see its name, author and difficulty. Locked
    puzzles show "?".
  - Finished worlds get a bone-white outline and a skull badge. Finishing a world pans to the
    newly opened worlds, which fade in.
  - Enemies say a few lines before the fight (first attempt only) and get last words when they
    fall.
- Saved progress: wins on the 21 earlier story puzzles still in the story still count. The
  other 26 aren't in the new story, and later worlds unlock tier by tier, so some players may
  find worlds locked that they'd reached before.

### Windows: sound and options
- **Before:** the game was silent unless unmuted in Options.
- **Now:** music and sound effects play by default. Mute, music volume and sound volume are
  remembered between sessions.
- Options has a new look, a **Show Damage Math** setting and **Replay Tutorial**.
- Web: still silent, with no enemy dialog, as before.

### Layout
- A big hand squeezes its cards closer together instead of spreading over the discard pile, and
  no longer covers the Reorder Cards switch.
- Card descriptions never scroll: long text shrinks to fit, and text on many cards is a little
  larger where there's room.
- The enemy's statuses (Retaliate, Corrode) sit right under its debuffs, and every status box is
  the same width.

### Text
- Heartbeat's designer credit reads "Moribam" (was "moribam").

---

## 5. Seeing what a card will do

- **Live damage:** while you hold an attack over the play area, its damage number shows what it
  will really deal, in gold, when your statuses change it.
- **Converted attacks say what they become:** "Deal 3 damage" changes to "Apply 3 Vulnerable"
  (Poison), "Apply 3 Burn" (Flame) or "Gain 3 energy" (Charge).
- **Damage math:** a box beside the held card shows how the damage is worked out, for example
  "4 (base) / +2 (sharp) = 6 / x2 (critical) = 12 damage". Windows players can turn it off in
  Options > Show Damage Math.
- **Statuses light up:** your statuses and the enemy's that will react to the held card glow
  and pulse.
- **Counts on the card:** Heartbeat, Thunderbolt, Shovel and Balance show their current damage,
  for example "(Deals 7 damage)".
- **Statuses on hover:** hovering a status shows its description (it used to need a click), and
  the text shows real numbers: "Your next 2 attacks deal double damage" instead of "X".
- **One box per status:** two Criticals show as one "Critical 2" box. They still act separately.
- **Card preview** explains keywords used in the card's text (Trash, Reclaim, Vulnerable and
  others).
