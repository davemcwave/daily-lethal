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
Tools\run-puzzle-tests.cmd                      # all puzzles, headless, ~6 min
Tools\run-puzzle-tests.cmd --only=kraken        # by file/enemy name or date (comma-separated)
Tools\run-puzzle-tests.cmd --cards=scorch       # puzzles that use a card
Tools\run-puzzle-tests.cmd watch --only=kraken  # play it in a visible game window
```

Works from cmd, PowerShell and Git Bash. Exit code 0 = all passed, 1 = something failed. Each line
is `PASS`, `FAIL  <puzzle>  -- <why>` (the step, the card and the reason, e.g. "Lunge in hand but not
playable (cost 1, energy 0)") or `SKIP`. Results are deterministic. The "leaked at exit" /
"resources still in use" errors Godot prints when it quits are normal and not failures.

Baseline (2026-11-08): **256 of the 275 released puzzles pass; 0 fail**. The other 19 are skipped
on purpose (reason recorded per puzzle). Any new FAIL is a regression or a puzzle that changed.

The runner is `Scripts/PuzzleResolver.gd` (CLI mode). Its other options: `--report=out.json`,
`--speed=N` (time scale, default 10), `--timeout=S` (seconds before a hung puzzle fails),
`--max-choices=N` (see below).

### Where solutions come from

- **Scene puzzles** (`Scenes/Puzzles/*.tscn`, 2025-04 to 2026-02): a recorded solution in
  `Scenes/Puzzles/Solutions/<date>-<enemy>.tres` (or `card_solution` on the puzzle). Winning a
  puzzle in a non-exported run records it there automatically, overwriting the old one.
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
