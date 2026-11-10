# Daily Lethal

Godot 4.4 (GDScript) daily puzzle card game, published at playlethal.fun. Each puzzle gives you a
hand of cards and the enemy must die before you run out of energy/health.

## Godot

Godot 4.4.1 lives in `C:\Tools\Godot\` (on PATH as `godot`, which runs the console build).
Close the Godot editor before editing `.tscn`/`.tres` files by hand, or it will overwrite them.

```
godot --headless --path . --import                                     # rebuild .godot/ cache
godot --headless --path . --check-only --script res://Scripts/Card.gd  # parse-check a script
```

## Testing: run this after every gameplay change

```
Tools\run-all-tests.cmd                         # every suite + one summary, ~10 min (--pairs adds ~18 min)
Tools\run-all-tests.cmd --only=content,lab      # just some: content, lab, effects, puzzles, pairs
Tools\run-puzzle-tests.cmd                      # all puzzles, headless, ~6 min
Tools\run-puzzle-tests.cmd --only=kraken        # by file/enemy name or date (comma-separated)
Tools\run-puzzle-tests.cmd --cards=scorch       # puzzles that use a card
Tools\run-puzzle-tests.cmd watch --only=kraken  # play it in a visible game window
```

Works from cmd, PowerShell and Git Bash. Exit code 0 = all passed, 1 = something failed. Each line
is `PASS`, `FAIL  <puzzle>  -- <why>` (the step, the card and the reason, e.g. "Lunge in hand but not
playable (cost 1, energy 0)") or `SKIP`. Results are deterministic. The "leaked at exit" /
"resources still in use" errors Godot prints when it quits are normal and not failures.

Baseline (2026-11-10): **262 of the 282 released puzzles pass; 0 fail**. The other 20 are skipped
(no known solution, or a reason recorded per puzzle). Any new FAIL is a regression or a puzzle that
changed. Test only with the pre-branch recordings and Formspree solutions: check
`git status Scenes/Puzzles/Solutions` is clean before trusting a run.

The runner is `Scripts/PuzzleResolver.gd` (CLI mode). Its other options: `--report=out.json`,
`--speed=N` (time scale, default 10), `--timeout=S` (seconds before a hung puzzle fails),
`--max-choices=N` (see below).

### Where solutions come from

- **Scene puzzles** (`Scenes/Puzzles/*.tscn`, 2025-04 to 2026-02): a recorded solution in
  `Scenes/Puzzles/Solutions/<date>-<enemy>.tres` (or `card_solution` on the puzzle). Winning a
  puzzle in a dev run records it there, overwriting the old one, only when the run was
  started with `--record-solution` (e.g. `-- --puzzle=roc --record-solution`).
- **URL puzzles** (2026-02-23 onward): defined in `custom-redirects.json` (`?cards=...&php=&pnrg=&ehp=`).
  Their solutions, and those of scene puzzles with no recording, are in `Tests/puzzle_solutions.json`,
  converted from community Formspree submissions. Each entry keeps the submitted `source` text.
  Step format: `{"card": "Armory", "picks": ["Slash", "Cleave"]}`, `{"card": "Potion", "effect": "heal"}`
  (`effect` can be a list, e.g. Echo + Potion), `{"card": "Revive", "copy": true}` (Trace copy vs
  original). `"skip": "<reason>"` excludes a puzzle; delete it once the solution works.
- When a solution leaves a choice out (an effect, a chooser pick, which copy of a card), the
  runner tries the options, up to `--max-choices` (default 64), and notes the choices that won.

Not tested on purpose: `Puzzle.tscn` (base scene), `TestPuzzle.tscn` (scratch placeholder),
`Scenes/Puzzles/Nightmare/` (unused).

### New community submissions

`/submit-puzzle` requires the creator to beat their puzzle with **🧪 Test Puzzle**: on the win
screen the game saves the winning moves to `localStorage` (`Background.publish_test_puzzle_solution`),
the Share button becomes **USE THIS SOLUTION**, and the form fills itself in. Formspree then receives
`solution_steps` (JSON in the `Tests/puzzle_solutions.json` step format, ready to paste in) and
`solution_source` (`recorded`, or `typed` if the creator ticked "I'll type my solution myself").
The game must be re-exported and deployed together with the submit page, or creators can't submit.

## Cards and effects as data (modular content)

Goal: players build custom cards, effects and buffs **in the game** (desktop/Steam and web), so
built-in and player-made content share one data format and one builder.

- `Scripts/Content/EffectRegistry.gd`: every `Scenes/*CardEffect.tscn` is an effect type, found
  automatically (id = scene name minus "CardEffect": `Damage`, `Draw`, `Condition`, ...). Its
  parameters are the script's exported variables. `create_effect(definition)` /
  `describe_effect(effect)` convert between effects and data like
  `{"type": "Damage", "params": {"damage_amount": 3}}` (only non-default params are stored;
  nested effects go in `children` or an effects-list param such as Potion's choices).
- `Scripts/Content/CardFactory.gd`: `create_card(definition)` / `describe_card(card)`; same
  format as the Card Lab's custom-card JSON. The Card Lab (`UrlCaptureLabel._configure_card`)
  builds through it; its original effect types ("DamageCardEffect" + "damage") still work.
- Content tests: `godot --headless --path . --script res://Tests/content_tests.gd` (registry,
  every built-in card round-trips card -> data -> card, Card Lab output unchanged vs
  `Tests/card_lab_golden.json`).
- `Tools\run-puzzle-tests.cmd --rebuilt-cards` replays the puzzles with data-built twins of every
  card whose script only builds its description text.
- Card Lab inputs: `godot --headless --path . --script res://Tests/card_lab_input_tests.gd`. Every
  input of every offered effect (and every buff's own settings) shows the effect's real value
  and, when changed in the Card Lab, changes the built effect.
- Effects work: `python Tools/check_effects.py` plays every effect in a test puzzle (default and
  `SMOKE_CONFIG` settings) and fails one that hits a script error or changes nothing.
- Cards work together: `python Tools/check_card_pairs.py` (~18 min, `--only=pair@scrap+` for one
  card) plays every built-in card followed by every built-in card (3,600 pairs) and fails a pair
  that hits a script error, hangs, or leaves the game broken (a card in two places, a play that
  never finished, a locked play area, a chooser left open). Run it after play-order changes.
- Card Lab share codes (no server): **Share code** copies `LETHAL2-` + base64url(deflate(compact JSON))
  holding the custom cards (up to 10, each with its copies) and the Test hand settings; **Import code**
  loads one (old `LETHAL1-` and one-card codes too). Format and checks are in
  `Scripts/Content/ShareCode.gd` (built-in cards by name only, numbers clamped, size limits); tested
  in `Tests/content_tests.gd`. Dev: `-- --import-code=<code> [--import-now] [--try-now]`.
- Card Lab saving: cards and the Test hand save to `user://card_lab.json` on every change and load
  when the game starts (`CardBuilder._save_lab` / `_load_saved_lab`). Headless runs and dev flags
  (`--card-json`, `--try-cards`, `--import-code`, `--screenshot`) never write it. Import code offers
  **Add to my cards** (keeps yours, up to 10) or **Replace all**.
- Card Lab on the web: `card-lab/index.html` (playlethal.fun/card-lab) redirects to
  `/desktop/?card_lab=1`; `Background._open_card_lab_from_url()` opens the Card Lab, and on the web
  Main menu goes to the site's home page. Needs a Web Desktop export to go live.
- Card data never names files: buffs, debuffs, cards and icons are stored by name ("Sharp"), and
  `EffectRegistry.allowed_scene_path()` is the only way data reaches a scene (old paths to the
  same scenes still load; anything else is refused). Shared puzzle links are untrusted input.

## Launching a specific puzzle

```
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- --puzzle=demogorgon   # scene puzzle, by file name
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- --url=2026-05-15      # URL puzzle, by date
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- "--url=?cards=..."    # creator test, as from /submit-puzzle
```

## Rules for this repo

- Save scenes and resources as text (`.tscn`/`.tres`), never `.scn`/`.res`. Everything was converted
  on 2026-11-08 so it can be diffed and edited.
- Keep `editor/export/convert_text_resources_to_binary=false` in `project.godot`. Several runtime
  folder scans match `ends_with(".tscn")` (e.g. finding today's puzzle in `Scene.gd`) and would miss
  the `.tscn.remap` stubs a binary export produces.
- Story progress saves store puzzle scene paths. `Background.load_story_progress()` migrates
  old `.scn` paths; keep that working if paths change again.
- The dated folders, `desktop/`, `mobile/` and other HTML at the root are the published website and
  web exports, not source.

## Code notes

- `Card.gd` is the base card; cards override `play()`. Play order is documented in
  `Docs/card-play-order.md`.
- Debuffs (`Enemy.gd`): iterate a `.duplicate()` of the debuff list, check
  `is_instance_valid(debuff) and not debuff.is_queued_for_deletion()`, and `await debuff.activate()`
  (BurnDebuff is a coroutine).
