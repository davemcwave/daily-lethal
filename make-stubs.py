import os
import argparse
from datetime import datetime, timedelta

ROOT_STUB = """<!doctype html>
<meta charset="utf-8">
<title>Lethal – {date}</title> 
<script>
  // Pick up device preference
  let deviceType = localStorage.getItem('device_type');
  if (deviceType !== 'desktop' && deviceType !== 'mobile') {{
    deviceType = 'mobile'; // default fallback
  }}

  // Redirect
  location.replace("/" + deviceType + "/{date}/"); 
</script>
"""

DESKTOP_STUB = """<!doctype html>
<meta charset="utf-8">
<title>Lethal – {date}</title>
<script>
  // Build absolute URL to the evergreen build at the site root
  const url = new URL("/desktop/", window.location.origin);
  url.searchParams.set("puzzle_date", "{date}");

  // Redirect
  location.replace(url.toString());
</script>
"""

MOBILE_STUB = """<!doctype html>
<meta charset="utf-8">
<title>Lethal – {date}</title>
<script>
  // Build absolute URL to the evergreen build at the site root
  const url = new URL("/mobile/", window.location.origin);
  url.searchParams.set("puzzle_date", "{date}");

  // Redirect
  location.replace(url.toString());
</script>
"""

def write_file(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def iter_release_days(start: datetime, end: datetime, anchor: datetime, cadence_days: int):
    """
    Yield all dates within [start, end] that are congruent to the anchor
    under the specified cadence (e.g., every 2 days).
    """
    if cadence_days <= 0:
        raise ValueError("cadence_days must be >= 1")

    # Find the first release >= start that aligns with anchor mod cadence
    # We do this by shifting from anchor in steps of cadence until >= start
    d = anchor
    if d < start:
        delta_days = (start - d).days
        steps = (delta_days + cadence_days - 1) // cadence_days  # ceil
        d = anchor + timedelta(days=steps * cadence_days)

    while d <= end:
        yield d
        d += timedelta(days=cadence_days)

def make_stubs_for_range(start_date: str, end_date: str, out_dir: str, anchor_date: str = None, cadence_days: int = 2):
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    if end < start:
        raise ValueError("End date must be >= start date")

    anchor = datetime.strptime(anchor_date, "%Y-%m-%d") if anchor_date else start

    created = 0
    for day in iter_release_days(start, end, anchor, cadence_days):
        date_str = day.strftime("%Y-%m-%d")

        # Root-level (auto device) stub
        root_path = os.path.join(out_dir, date_str, "index.html")
        write_file(root_path, ROOT_STUB.format(date=date_str))

        # Desktop stub
        desktop_path = os.path.join(out_dir, "desktop", date_str, "index.html")
        write_file(desktop_path, DESKTOP_STUB.format(date=date_str))

        # Mobile stub
        mobile_path = os.path.join(out_dir, "mobile", date_str, "index.html")
        write_file(mobile_path, MOBILE_STUB.format(date=date_str))

        created += 1
        print(f"Created stubs for {date_str}")

    if created == 0:
        print("No release-day dates fell within the range (check anchor/cadence).")
    else:
        print(f"Done. Generated {created*3} files across {created} release days.")

def main():
    p = argparse.ArgumentParser(description="Generate Lethal puzzle redirect stubs on release days.")
    p.add_argument("--start", required=True, help="Start date (YYYY-MM-DD)")
    p.add_argument("--end", required=True, help="End date (YYYY-MM-DD)")
    p.add_argument("--out-dir", default=".", help="Output root directory (default: current dir)")
    p.add_argument("--anchor", help="Anchor release date (YYYY-MM-DD). Defaults to --start if omitted.")
    p.add_argument("--cadence", type=int, default=2, help="Release cadence in days (default: 2)")
    args = p.parse_args()

    make_stubs_for_range(args.start, args.end, args.out_dir, args.anchor, args.cadence)

if __name__ == "__main__":
    main()
