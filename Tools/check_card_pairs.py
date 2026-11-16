"""Plays every built-in card followed by every built-in card (3,700+ pairs) and
reports the pairs that break: a script error, a hang, or a game left in a state
it can't continue from (a card in two places, a play that never finished, a
locked play area, a chooser left open, negative energy).

  python Tools/check_card_pairs.py              # all pairs, 4 processes in parallel
  python Tools/check_card_pairs.py --jobs=6
  python Tools/check_card_pairs.py --only=pair@scrap+,pair@echo+potion

Each pair is its own test puzzle (10 HP, 10 energy, enemy 99 HP) with the two
cards plus Slash, Pound, Rebound and Revive: it plays Slash, then the first card,
then the second. Choosers pick a filler card, effect choices the first option.
"The first card used up the second" (Scrap discarded it, Tribute trashed it, too
little energy) is fine and isn't reported. Exit code 0 = no broken pairs.
"""
import re
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run_shard(index: int, count: int, only: str) -> subprocess.Popen:
    args = ["cmd", "/c", str(ROOT / "Tools" / "run-puzzle-tests.cmd"), "--effect-smoke=pairs",
            f"--shard={index}/{count}"]
    if only:
        args.append(f"--only={only}")
    # stderr into stdout, so each SCRIPT ERROR lands under the pair that caused it.
    return subprocess.Popen(args, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, encoding="utf-8", errors="replace")


def parse(log: str, pairs: dict) -> None:
    current = None
    for line in log.splitlines():
        start = re.match(r"### PUZZLE \d+/\d+ effect:Pair@(\S+)", line)
        if start:
            current = pairs.setdefault(start.group(1), {"errors": [], "status": None})
            continue
        if current is None:
            continue
        if line.startswith("SCRIPT ERROR:") or line.startswith("ERROR:"):
            message = line.split(":", 1)[1].strip()
            if "leaked" in message or "still in use" in message:
                continue
            if message not in current["errors"]:
                current["errors"].append(message)
        elif line.startswith("   at:") and current["errors"] and "@" not in current["errors"][-1]:
            current["errors"][-1] += " @ " + line.split("at:", 1)[1].strip()
        # (The run's summary repeats FAIL lines at the end: match the pair by name.)
        status = re.match(r"(PASS|FAIL|SKIP)\s+effect:Pair@(\S+) \(pairs\)\s*(?:--\s*(.*))?", line)
        if status and status.group(2) in pairs and pairs[status.group(2)]["status"] is None:
            pairs[status.group(2)]["status"] = status.group(1) + ((" -- " + status.group(3)) if status.group(3) else "")


def main() -> int:
    jobs = int(next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--jobs=")), "4"))
    only = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--only=")), "")
    started = time.time()
    procs = [run_shard(i + 1, jobs, only) for i in range(jobs)]
    pairs: dict = {}
    crashed = []
    for number, proc in enumerate(procs, 1):
        out, _ = proc.communicate()
        before = len(pairs)
        parse(out, pairs)
        # Every pair the process was given must have started and finished; if not,
        # Godot itself died (a crash kills the process, not just one pair).
        totals = re.findall(r"### PUZZLE \d+/(\d+) effect:Pair@", out)
        expected = int(totals[0]) if totals else -1
        if expected < 0 or len(pairs) - before < expected or "==== PUZZLE TEST SUMMARY" not in out:
            last = re.findall(r"### PUZZLE \d+/\d+ effect:Pair@(\S+)", out)
            crashed.append((number, len(pairs) - before, expected, last[-1] if last else "?", out.splitlines()[-25:]))

    broken = {k: v for k, v in pairs.items() if v["errors"] or not (v["status"] or "").startswith("PASS")}
    # Group by what went wrong, so one bug hit by 60 pairs reads as one line.
    by_problem = defaultdict(list)
    for pair, info in broken.items():
        problems = list(info["errors"])
        if not (info["status"] or "").startswith("PASS"):
            reason = info["status"] or "didn't finish"
            reason = re.sub(r"step \d+/\d+ \(play ([^)]*)\)", r"playing \1", reason)
            problems.append(reason)
        for problem in problems:
            by_problem[problem].append(pair)

    print(f"{len(pairs)} pairs played in {time.time() - started:.0f}s, {len(broken)} broken")
    for number, got, expected, last, tail in crashed:
        print(f"\nPROCESS {number} STOPPED EARLY: {got} of {expected} pairs, last one started: {last}")
        print("      " + "\n      ".join(tail))
    for problem, hit in sorted(by_problem.items(), key=lambda kv: -len(kv[1])):
        print(f"\n{len(hit):4} pair(s): {problem}")
        print("      " + ", ".join(sorted(hit)[:25]) + (" ..." if len(hit) > 25 else ""))
    return 1 if broken or crashed else 0


if __name__ == "__main__":
    sys.exit(main())
