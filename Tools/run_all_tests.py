"""Runs every test suite, one after another, and prints one summary.

    Tools\\run-all-tests.cmd                  everything except card pairs (~10 min)
    Tools\\run-all-tests.cmd --pairs          also every card followed by every card (+~18 min)
    Tools\\run-all-tests.cmd --only=content,lab   just some suites (names below)

Suites:
    content   Tests/content_tests.gd: effect registry, cards as data, share codes, font
    lab       Tests/card_lab_input_tests.gd: every Card Lab input changes the real card
    effects   Tools/check_effects.py: every effect works in a test puzzle
    puzzles   Tools/run-puzzle-tests.cmd: every released puzzle's solution still wins
    pairs     Tools/check_card_pairs.py: every card followed by every card (only with --pairs)

Exit code 0 = every suite passed, 1 = something failed. Override the Godot folder
with GODOT_DIR.
"""
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = Path(os.environ.get("GODOT_DIR", r"C:\Tools\Godot")) / "Godot_v4.4.1-stable_win64_console.exe"
TIMEOUT = 20 * 60  # a suite that hangs (e.g. a script error in a test's _init) fails instead


def godot_script(script: str) -> list:
    return [str(GODOT), "--headless", "--path", str(ROOT), "--script", script]


SUITES = [
    # name, command, how to read its result line, what a failure line starts with
    ("content", lambda: godot_script("res://Tests/content_tests.gd"), r"^checks \d+, failed \d+", "FAIL"),
    ("lab", lambda: godot_script("res://Tests/card_lab_input_tests.gd"), r"^checks \d+, failed \d+", "FAIL"),
    ("effects", lambda: [sys.executable, str(ROOT / "Tools" / "check_effects.py")], r"(all effects work|\d+ .*fail.*)", "FAIL"),
    ("puzzles", lambda: ["cmd", "/c", str(ROOT / "Tools" / "run-puzzle-tests.cmd")], r"^passed \d+, failed \d+, skipped \d+", "FAIL"),
    ("pairs", lambda: [sys.executable, str(ROOT / "Tools" / "check_card_pairs.py")], r"\d+ pairs played.*", "BROKEN"),
]


def run_suite(name, command, result_pattern, fail_prefix):
    started = time.time()
    try:
        done = subprocess.run(command(), cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True, encoding="utf-8", errors="replace", timeout=TIMEOUT)
        output, code = done.stdout, done.returncode
    except subprocess.TimeoutExpired as hung:
        output, code = (hung.stdout or "") if isinstance(hung.stdout, str) else "", 1
        output += f"\nFAIL  {name} didn't finish in {TIMEOUT // 60} minutes"
    lines = output.splitlines()
    summary = next((l.strip() for l in reversed(lines) if re.search(result_pattern, l.strip())), "")
    failures = []
    for line in lines:
        stripped = line.strip()
        if (stripped.startswith(fail_prefix) or stripped.startswith("FAIL")) and stripped not in failures:
            failures.append(stripped)
    passed = code == 0 and (summary != "" or name == "effects")
    return passed, summary or f"exit code {code}", failures, time.time() - started


def main() -> int:
    args = sys.argv[1:]
    wanted = None
    for arg in args:
        if arg.startswith("--only="):
            wanted = [n.strip() for n in arg.split("=", 1)[1].split(",") if n.strip()]
    if not GODOT.exists():
        print(f"Godot not found at {GODOT}. Set GODOT_DIR to the folder containing it.")
        return 2

    results = []
    for name, command, pattern, fail_prefix in SUITES:
        if wanted is not None and name not in wanted:
            continue
        if wanted is None and name == "pairs" and "--pairs" not in args:
            continue
        print(f"== {name} ...", flush=True)
        passed, summary, failures, seconds = run_suite(name, command, pattern, fail_prefix)
        for failure in failures:
            print("   " + failure)
        print(f"   {'PASS' if passed else 'FAIL'}  {summary}  [{seconds:.0f}s]", flush=True)
        results.append((name, passed, summary))

    print("")
    print("==== ALL TESTS ====")
    for name, passed, summary in results:
        print(f"{'PASS' if passed else 'FAIL'}  {name:<8} {summary}")
    failed = [name for name, passed, _ in results if not passed]
    print("everything passed" if not failed else "failed: " + ", ".join(failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
