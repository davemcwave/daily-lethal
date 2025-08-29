#!/usr/bin/env python3
import argparse
import os
import re
import shutil
from pathlib import Path

INDEX_TEMPLATE = """<!doctype html>
<meta charset="utf-8">
<title>Lethal – {date}</title> 
<script>
  // Pick up device preference
  let deviceType = localStorage.getItem('device_type');
  if (deviceType !== 'desktop' && deviceType !== 'mobile') {{
    deviceType = 'mobile'; // default fallback
  }}

  // Redirect
  location.replace("/" + deviceType +  "/{date}/"); 
</script>
"""


DATE_DIR_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

def find_date_dirs(base: Path):
    for entry in base.iterdir():
        if entry.is_dir() and DATE_DIR_RE.match(entry.name):
            yield entry

def clear_directory_contents(dir_path: Path, dry_run: bool):
    for child in dir_path.iterdir():
        if child.is_symlink() or child.is_file():
            print(f"DELETE file: {child}")
            if not dry_run:
                try:
                    child.unlink()
                except FileNotFoundError:
                    pass
        elif child.is_dir():
            print(f"DELETE dir:  {child}")
            if not dry_run:
                shutil.rmtree(child, ignore_errors=True)

def write_index(dir_path: Path, date_str: str, dry_run: bool):
    index_path = dir_path / "index.html"
    print(f"WRITE file: {index_path}")
    if not dry_run:
        index_path.write_text(INDEX_TEMPLATE.format(date=date_str), encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(
        description="Reset date-named subdirectories (YYYY-MM-DD) to contain only an index.html that redirects to /{deviceType}/YYYY-MM-DD/."
    )
    parser.add_argument(
        "--base",
        type=str,
        default=".",
        help="Base directory to scan (default: current directory).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would happen without making changes.",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip confirmation prompt.",
    )
    args = parser.parse_args()

    base = Path(args.base).resolve()
    if not base.exists():
        print(f"Base path does not exist: {base}")
        raise SystemExit(1)

    targets = list(find_date_dirs(base))
    if not targets:
        print("No YYYY-MM-DD directories found.")
        return

    print("Targets:")
    for t in targets:
        print(f"  - {t}")

    if not args.yes and not args.dry_run:
        resp = input("\nProceed with deletions and index writes? (y/N): ").strip().lower()
        if resp != "y":
            print("Aborted.")
            return

    for d in targets:
        date_str = d.name
        clear_directory_contents(d, args.dry_run)
        write_index(d, date_str, args.dry_run)

    if args.dry_run:
        print("\nDRY RUN complete. No changes were made.")
    else:
        print("\nDone.")

if __name__ == "__main__":
    main()
