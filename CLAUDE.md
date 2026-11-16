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

Players see the Card Lab as the **Puzzle Lab** (main menu, title, Library buttons): two tabs,
Custom Cards (a tab per card) and Custom Puzzle (the test puzzle). The puzzle's hand can use any subset of
the Lab's cards (a card can have 0 copies in it); a puzzle's share code carries only the cards it uses. Code, files and the
/card-lab web address keep the Card Lab / CardBuilder names.

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
- Share codes (no server): the Library's **Share code** copies `LETHAL3-` + base64url(deflate(compact JSON))
  holding cards (each with its author) and named puzzles (`ShareCode.encode_library` /
  `decode_library`; a puzzle's hand points at its cards by index, built-in cards by name). The Card
  Lab makes, the Library keeps: the Lab's only such button is **Save to Library** (its cards plus
  the Test hand as one puzzle; Test hand page: Puzzle name, Your name). The Library's **Import code**
  (`Scripts/LibraryImport.gd`, both tabs) adds cards only, or cards and puzzles; a custom card's
  **Edit in Puzzle Lab** sends it to the Lab (`Background.card_lab_incoming`; a custom puzzle with its cards: `card_lab_incoming_puzzle`, asking first if the Lab has unsaved cards). Imports still read `LETHAL2-`, `LETHAL1-` and one-card codes. Format and checks are in
  `Scripts/Content/ShareCode.gd` (built-in cards by name only, numbers clamped, size limits); tested
  in `Tests/content_tests.gd`. Dev: `-- --import-code=<code> [--import-now] [--try-now]`.
- Card Lab saving: cards and the Test hand save to `user://card_lab.json` on every change and load
  when the game starts (`CardBuilder._save_lab` / `_load_saved_lab`). Headless runs and dev flags
  (`--card-json`, `--try-cards`, `--import-code`, `--screenshot`) never write it. Import code offers
  **Add to my cards** (keeps yours, up to 10) or **Replace all**.
- Puzzle Lab and Library on the web: `puzzle-lab/index.html` (playlethal.fun/puzzle-lab) opens
  `/desktop/?puzzle_lab=1` (phones get a "needs a mouse" page); `library/index.html` opens
  `/desktop/?library=1`; `card-lab/` forwards to `/puzzle-lab/` (old `?card_lab=1` still works).
  `Background._open_card_lab_from_url()` reads those flags. Puzzles started inside the game (Lab
  test, Library) use Background's url override on the web too (`UrlCaptureLabel`), and the Library's
  Main Menu goes to the site's home page. Web exports include `Data/*.json`. Needs a Web Desktop
  export to go live.
- Custom cards inside cards: a card list param (Pick to Create's `card_scenes`) may hold a custom
  card as its definition; `CustomCardScene` (a Resource whose `instantiate()` calls CardFactory)
  stands in for the scene. A held card holds no custom cards of its own
  (`EffectRegistry.without_embedded_cards`), so nothing nests forever. The Lab offers your cards
  there and keeps the copies in step with your edits (`CardBuilder._sync_embedded_cards`). The
  puzzle runner finds a custom card in the hand by name.
- Card data never names files: buffs, debuffs, cards and icons are stored by name ("Sharp"), and
  `EffectRegistry.allowed_scene_path()` is the only way data reaches a scene (old paths to the
  same scenes still load; anything else is refused). Shared puzzle links are untrusted input.

## Story mode (Windows desktop build)

- `Data/story_worlds.json` is the story: `tiers` (one world or a pair) and `worlds` (name, idea,
  cards taught, puzzles in play order). A tier opens when every world of the tier before it is
  finished; inside a world the puzzles open one at a time (boss last). It was generated from the
  progression web (`/progression/review`); edit it by hand from now on.
- Each puzzle's `id` is its save key: a scene path (`scene`), `url:<date>` (a released URL puzzle,
  with its `search` copied in), or `story:<name>` (made for the story: `search` plus `solution`).
  Story mode doesn't read `custom-redirects.json`, so a fix to a released URL puzzle must be copied
  into its `search` here too. The Windows export includes `Data/*.json` (`include_filter`).
- Dialog: story puzzles show their pre-fight dialog (once per visit, not on retries; elsewhere
  dialog stays off). A puzzle's optional `"dialog": {"first": "Enemy"|"Player", "lines": [...],
  "death": "..."}` in the story file is used (hurt lines are off: too distracting); without it a
  scene puzzle falls back to its scene's `dialogue_lines` / `enemy_hurt_lines` / `death_line`.
- Each world's `story` is the world-building text players see (the world's hover card); `idea` is
  the design note the progression pages use. Finished worlds keep a bone-white outline and a skull
  badge. When finishing a world opens the next tier, the map pans there, the new worlds' color
  comes in and each of their puzzles blinks once, in order (no popups).
- `Scripts/StoryView.gd` draws the map from that file; `Background.start_story_puzzle()` plays an
  entry. Dev: `-- --story-unlock-all`, `--story-scroll=<px>`, `--story-hover=<n>`,
  `--story-hover-world=<id>`, `--story-demo-complete=<world id>` (with `--screenshot=`).
- `Tools\run-puzzle-tests.cmd --story` plays every story puzzle (`--only=` matches enemy or world name).

## Puzzle Archive (desktop)

- Main menu (desktop): Play (larger), Daily, Library, Card Lab; Options and Discord are icons in the
  top-right corner. DAILY plays today's puzzle, or the latest one if today's isn't out. LIBRARY opens
  `Scenes/ArchiveView.tscn`: every released daily in one sortable table (click a column title) with
  filters (search across every field, any number of cards (all must be in the puzzle), difficulty,
  beaten, enemy status). Double-click or PLAY to play; the win screen's NEXT PUZZLE plays the next
  row of the current list. Beaten puzzles are saved in `user://archive_progress.save`.
  `Scripts/PuzzleArchive.gd` loads the list, fetches newer dailies and picks the daily.
- Data: `Data/puzzle_archive.json`, built by `python Tools/build_puzzle_archive.py` from
  `manifest.json`, `custom-redirects.json`, the puzzle scenes, Background's difficulty/author tables
  and the Formspree exports. Rerun it when releasing puzzles. On opening, the archive also fetches
  `https://playlethal.fun/custom-redirects.json` so dailies released after a build still appear.

## Custom Library (desktop)

- `Scripts/Content/CustomLibrary.gd`: the player's custom cards and puzzles in
  `user://custom_library.json` (local to the device). Filled by the Card Lab's **Save to Library**
  and by importing a share code; a puzzle always brings its cards. Names are unique (any case):
  saving or importing a card or puzzle whose name is taken asks to overwrite it
  (`CustomLibrary.conflicts` / `save`); overwriting keeps the id, so puzzles using a card still work. A card a custom puzzle uses can't be deleted until that puzzle is.
- Both Library tabs list them with the official ones, marked in purple (CUSTOM in the Date column,
  a CUSTOM tag on the card face) with an **All sources / Official / Custom** filter, plus Share code
  and Delete. Custom puzzles have id `custom:<id>`, no difficulty, and play like the Card Lab's
  test puzzle (a `?cards=` query with no date; not treated as a creator's /submit-puzzle test).

## Cards screen (desktop)

- The Library's Cards tab (`Scenes/CardsView.tscn`; Puzzles | Cards tabs switch between the two): every built-in card (one per in-game name) as it
  looks in a hand (cards no released puzzle uses, i.e. test cards, are left out), with filters like
  the archive's (search, cost, colors (any number, OR), world, author, sort). Clicking one shows its text, keyword tooltips, the
  story world that introduces it, how many archive puzzles use it, and PUZZLES WITH THIS CARD (opens
  the archive with that card ticked via `Background.archive_preset_cards`). Nothing is hidden.
  Faces come from `Scripts/CardFaces.gd` (the card scene with its script and effects removed after
  reading its text); the archive's card filter uses them too, to preview a card on hover.

## Launching a specific puzzle

```
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- --puzzle=demogorgon   # scene puzzle, by file name
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- --url=2026-05-15      # URL puzzle, by date
C:\Tools\Godot\Godot_v4.4.1-stable_win64.exe --path . -- "--url=?cards=..."    # creator test, as from /submit-puzzle
```

## Rules for this repo

- Web exports: always no audio and no enemy dialog (`OS.has_feature("web")` in AudioHandler,
  DialogHandler, Scene, Enemy; Options hides its audio rows). The Windows build keeps both on.

- Save scenes and resources as text (`.tscn`/`.tres`), never `.scn`/`.res`. Everything was converted
  on 2026-11-08 so it can be diffed and edited.
- Keep `editor/export/convert_text_resources_to_binary=false` in `project.godot`. Several runtime
  folder scans match `ends_with(".tscn")` (e.g. finding today's puzzle in `Scene.gd`) and would miss
  the `.tscn.remap` stubs a binary export produces.
- Story progress saves store story puzzle ids (scene paths for scene puzzles).
  `Background.load_story_progress()` migrates old `.scn` paths and the old map's `uid://` references;
  keep that working if paths change again.
- The dated folders, `desktop/`, `mobile/` and other HTML at the root are the published website and
  web exports, not source.

## Code notes

- `Card.gd` is the base card; cards override `play()`. Play order is documented in
  `Docs/card-play-order.md`.
- Debuffs (`Enemy.gd`): iterate a `.duplicate()` of the debuff list, check
  `is_instance_valid(debuff) and not debuff.is_queued_for_deletion()`, and `await debuff.activate()`
  (BurnDebuff is a coroutine).
