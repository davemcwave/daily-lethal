#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

DATE_DIR_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

def list_date_dirs(root: Path):
    if not root.exists() or not root.is_dir():
        return []
    return [p for p in root.iterdir() if p.is_dir() and DATE_DIR_RE.match(p.name)]

def ensure_dirs(names, dest_root: Path, dry_run: bool):
    created = 0
    if not dest_root.exists():
        print(f"CREATE dir: {dest_root}")
        if not dry_run:
            dest_root.mkdir(parents=True, exist_ok=True)
    for name in sorted(names):
        target = dest_root / name
        if target.exists():
            print(f"SKIP (exists): {target}")
            continue
        print(f"CREATE dir: {target}")
        if not dry_run:
            target.mkdir(parents=True, exist_ok=True)
        created += 1
    return created

def main():
    ap = argparse.ArgumentParser(
        description="Create empty /mobile/YYYY-MM-DD directories for each date directory found under /desktop."
    )
    ap.add_argument("--base", default=".", help="Base directory containing 'desktop' and 'mobile' (default: current dir)")
    ap.add_argument("--dry-run", action="store_true", help="Show actions without making changes")
    ap.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    args = ap.parse_args()

    base = Path(args.base).resolve()
    desktop = base / "desktop"
    mobile = base / "mobile"

    src_dirs = list_date_dirs(desktop)
    if not src_dirs:
        print(f"No YYYY-MM-DD directories found under {desktop}")
        return

    names = [d.name for d in src_dirs]
    print("Will ensure these exist under /mobile:")
    for n in sorted(names):
        print(f"  - {n}")

    if not args.dry_run and not args.yes:
        resp = input("\nProceed to create missing directories? (y/N): ").strip().lower()
        if resp != "y":
            print("Aborted.")
            return

    created = ensure_dirs(names, mobile, args.dry_run)
    if args.dry_run:
        print("\nDRY RUN complete. No changes were made.")
    else:
        print(f"\nDone. Created {created} directorie(s).")

if __name__ == "__main__":
    main()
