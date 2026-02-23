#!/usr/bin/env python3
"""
Utility script to generate /YYYY-MM-DD/index.html redirect stubs.

Usage:
    python scripts/create_date_redirect.py 2026-02-21
"""

from __future__ import annotations

import argparse
from pathlib import Path
import datetime

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Lethal – {date}</title>
  <script>
    (function redirectViaJson() {{
      var dateKey = "{date}";
      var requestPath = window.location.pathname || "";
      var platformMatch = requestPath.match(/^\/(desktop|mobile)\b/i);
      var requestedPlatform = platformMatch ? platformMatch[1].toLowerCase() : "";

      function applyPlatformPreference(url) {{
        if (!requestedPlatform) {{
          return url;
        }}

        var platformPrefix = "/" + requestedPlatform;
        var isPlatformPath = function(pathname) {{
          return pathname.startsWith("/desktop") || pathname.startsWith("/mobile");
        }};

        if (/^https?:\/\//i.test(url)) {{
          try {{
            var parsed = new URL(url);
            if (parsed.origin !== window.location.origin) {{
              return url;
            }}
            if (isPlatformPath(parsed.pathname)) {{
              return parsed.toString();
            }}
            parsed.pathname = platformPrefix + parsed.pathname;
            return parsed.toString();
          }} catch (platformErr) {{
            console.error("Failed to apply platform preference", platformErr);
            return url;
          }}
        }}

        if (isPlatformPath(url)) {{
          return url;
        }}
        return platformPrefix + url;
      }}

      fetch("/custom-redirects.json", {{ cache: "no-store" }})
        .then(function(response) {{
          if (!response.ok) {{
            throw new Error("Failed to load redirect map");
          }}
          return response.json();
        }})
        .then(function(map) {{
          var redirects = (map && map.date_redirects) ? map.date_redirects : map;
          var target = redirects[dateKey] || redirects["/" + dateKey];
          if (typeof target !== "string" || target.length === 0) {{
            return;
          }}
          var normalized;
          if (/^https?:\\/\\//i.test(target)) {{
            normalized = target;
          }} else if (target.startsWith("/")) {{
            normalized = target;
          }} else if (target.startsWith("?")) {{
            normalized = "/" + target;
          }} else {{
            normalized = "/" + target;
          }}
          if (normalized.indexOf("puzzle_date=") === -1) {{
            var joinChar = normalized.indexOf("?") === -1 ? "?" : "&";
            normalized = normalized + joinChar + "puzzle_date=" + encodeURIComponent(dateKey);
          }}
          normalized = applyPlatformPreference(normalized);
          window.location.replace(normalized);
        }})
        .catch(function(err) {{
          console.error("Date redirect error", err);
        }});
    }})();
  </script>
</head>
<body></body>
</html>
"""


def validate_date(value: str) -> str:
    import re

    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        raise argparse.ArgumentTypeError("Date must be in YYYY-MM-DD format.")
    return value


def main() -> None:
  parser = argparse.ArgumentParser(description="Generate /date/index.html redirect page(s).")
  parser.add_argument("date", nargs="?", type=validate_date, help="Puzzle date in YYYY-MM-DD format.")
  parser.add_argument("--start", type=validate_date, help="Start date (YYYY-MM-DD) for range generation.")
  parser.add_argument("--end", type=validate_date, help="End date (YYYY-MM-DD) for range generation (inclusive).")
  args = parser.parse_args()

  dates = []
  if args.date:
      dates.append(args.date)
  elif args.start and args.end:
      start = datetime.date.fromisoformat(args.start)
      end = datetime.date.fromisoformat(args.end)
      if end < start:
          raise SystemExit("End date must be on or after start date.")
      current = start
      while current <= end:
          dates.append(current.isoformat())
          current += datetime.timedelta(days=1)
  else:
      parser.error("Provide either a single DATE or both --start and --end.")

  for date_str in dates:
      folder = Path(date_str)
      folder.mkdir(parents=True, exist_ok=True)
      target_file = folder / "index.html"
      target_file.write_text(TEMPLATE.format(date=date_str), encoding="utf-8")
      print(f"Generated {target_file}")


if __name__ == "__main__":
    main()
