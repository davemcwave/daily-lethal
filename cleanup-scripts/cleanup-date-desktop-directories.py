#!/usr/bin/env python3
import argparse
import re
import shutil
from pathlib import Path

# NOTE: Double braces {{ }} are required so .format(...) doesn't treat JS braces as placeholders.
INDEX_TEMPLATE = """<!doctype html>
<meta charset="utf-8">
<title>Lethal – {date}</title>
<script>
  // Build absolute URL to the evergreen build at the site root
  const url = new URL("/" + "desktop" + "/", window.location.origin);
  url.searchParams.set("puzzle_date", "{date}");

  // Redirect
  location.replace(url.toString());
</script>
"""

DATE_DIR_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

def find_date_dirs_under_desktop(base: Path):
    desktop = base / "desktop"
    if not desktop.exists() or not desktop.is_dir():
        return []
    return [p for p in desktop.iterdir() if p.is_dir() and DATE_DIR_RE.match(p.name)]

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
    ap = argparse.ArgumentParser(
        description="Reset ./desktop/YYYY-MM-DD/ subfolders to contain only index.html that redirects via puzzle_date."
    )
    ap.add_argument("--base", default=".", help="Base directory (default: current directory)")
    ap.add_argument("--dry-run", action="store_true", help="Preview changes only")
    ap.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    args = ap.parse_args()

    base = Path(args.base).resolve()
    targets = find_date_dirs_under_desktop(base)

    if not targets:
        print(f"No YYYY-MM-DD directories found under {base / 'desktop'}.")
        return

    print("Targets:")
    for t in targets:
        print(f"  - {t}")

    if not args.dry_run and not args.yes:
        resp = input("\nProceed with deletions and index writes? (y/N): ").strip().lower()
        if resp != "y":
            print("Aborted.")
            return

    for d in targets:
        date_str = d.name
        clear_directory_contents(d, args.dry_run)
        write_index(d, date_str, args.dry_run)

    print("\nDRY RUN complete. No changes were made." if args.dry_run else "\nDone.")

if __name__ == "__main__":
    main()
