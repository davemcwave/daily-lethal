"""Checks that every card effect works: plays each one on a card in a test puzzle
(the runner's --effect-smoke mode) and fails an effect that

  - causes a script error (SCRIPT ERROR in the log while it was being set up or played), or
  - changes nothing (HP, energy, enemy, cards, statuses all the same afterwards).

  python Tools/check_effects.py                 # all modes
  python Tools/check_effects.py configured      # one mode: defaults | configured | buffs | highlight
  python Tools/check_effects.py --only=Buff,Heal

"defaults" plays each effect exactly as the Card Lab adds it (no settings changed);
"configured" uses PuzzleResolver.SMOKE_CONFIG, settings that make it do something.
"buffs" plays the Buff effect with every buff the Card Lab offers (on the player,
or the enemy for Corrode) and checks the buff is applied. "highlight" checks every
status lights up (or doesn't) while an attack / non-attack card is held over the
play area.
In defaults mode "changed nothing" is only a warning: an effect can legitimately do
nothing until it's set up (a Buff with no buff chosen). Effects the Card Lab doesn't
offer (no card uses them) only ever warn. Exit code 0 = all good, 1 = something failed.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run_mode(mode: str, only: str) -> str:
    args = ["cmd", "/c", str(ROOT / "Tools" / "run-puzzle-tests.cmd"), f"--effect-smoke={mode}"]
    if only:
        args.append(f"--only={only}")
    # stderr into stdout, so each SCRIPT ERROR lands under the effect that caused it.
    result = subprocess.run(args, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, encoding="utf-8", errors="replace")
    return result.stdout


def parse(log: str) -> tuple:
    """({effect id: {"errors": [...], "change": str, "status": "PASS"/"FAIL ..."}}, offered ids)"""
    effects: dict = {}
    offered: set = set()
    current = None
    for line in log.splitlines():
        card = re.match(r"SMOKE-CARD effect:[\w@]+ \(\w+\): (.*)", line)
        if card and current is not None:
            current["card"] = card.group(1)
        if line.startswith("OFFERED IN CARD LAB: "):
            offered = set(line.split(": ", 1)[1].strip().split(","))
        start = re.match(r"### PUZZLE \d+/\d+ effect:([\w@]+)", line)
        if start:
            current = effects.setdefault(start.group(1), {"errors": [], "change": None, "status": None, "card": None})
            continue
        if current is None:
            continue
        if line.startswith("SCRIPT ERROR:"):
            message = line[len("SCRIPT ERROR:"):].strip()
            if message not in current["errors"]:
                current["errors"].append(message)
        change = re.match(r"SMOKE-CHANGE effect:[\w@]+ \(\w+\): (.*)", line)
        if change:
            current["change"] = change.group(1)
        status = re.match(r"(PASS|FAIL|SKIP)\s+effect:[\w@]+", line)
        if status:
            current["status"] = line.strip()
    return effects, offered


def main() -> int:
    modes = [a for a in sys.argv[1:] if not a.startswith("--")] or ["defaults", "configured", "buffs", "highlight"]
    only = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--only=")), "")
    failed = 0
    for mode in modes:
        if mode == "highlight":
            # Statuses light up while a card is held over the play area: every one is
            # checked with an attack card and a non-attack card (HIGHLIGHT_EXPECT).
            lines = [l for l in run_mode(mode, only).splitlines() if l.startswith("HIGHLIGHT ")]
            print(f"\n=== highlight: {len(lines)} statuses ===")
            for line in lines:
                print(line)
                if " WRONG " in line:
                    failed += 1
            if not lines:
                print("FAIL  no highlight results")
                failed += 1
            continue
        effects, offered = parse(run_mode(mode, only))
        print(f"\n=== {mode} settings: {len(effects)} effects ({len(offered)} offered in the Card Lab) ===")
        for effect_id in sorted(effects):
            info = effects[effect_id]
            is_offered = effect_id in offered
            problems = []
            if mode == "buffs":
                # Buff effect with each buff the Card Lab offers: the buff must be applied.
                is_offered = True
                if effect_id != "Buff@none" and "statuses [] ->" not in (info["card"] or ""):
                    problems.append("buff wasn't applied: " + (info["card"] or "?"))
                info["change"] = info["card"] if effect_id != "Buff@none" else "(control: no buff)"
            if info["status"] is None or not info["status"].startswith("PASS"):
                problems.append(info["status"] or "didn't finish")
            if info["errors"]:
                problems.append("script error: " + " | ".join(info["errors"]))
            change = info["change"]
            if change in (None, "nothing"):
                if mode == "configured" and is_offered:
                    problems.append("changed nothing")
                else:
                    change = "nothing (warning: %s)" % ("defaults mode" if is_offered else "not offered in the Card Lab")
            if problems and not is_offered:
                print(f"warn  {effect_id:34} {'; '.join(problems)} (not offered in the Card Lab)")
                continue
            if problems:
                failed += 1
                print(f"FAIL  {effect_id:34} {'; '.join(problems)}")
            else:
                print(f"OK    {effect_id:34} {change}")
    print(f"\n{'all effects work' if failed == 0 else f'{failed} problem(s)'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
