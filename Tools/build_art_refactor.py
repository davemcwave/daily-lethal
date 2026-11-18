"""Builds the enemy art brief for Val: art-refactor/index.html (playlethal.fun/art-refactor)
and Docs/story-enemy-art.md / .csv, from story mode's puzzles (Data/story_worlds.json).

Every story enemy Val still has to draw, A to Z in one grid:
- the ones with art today show it (click for the original file, to redraw);
- the ones with no art (story-made and URL puzzles, which show the generic placeholder, and
  the two using the Leetha logo as a stand-in) show an empty circle.

When Val finishes an enemy, add its name to DRAWN_BY_VAL and rerun:
    python Tools/build_art_refactor.py
"""
import collections
import csv
import html
import json
import os
import re

# Enemies Val has already drawn: left off the page, marked done in the inventory.
# (Her other redraws, Elder, Green Dragon, Time Demon, Shoggoth, Modron, Wasp Swarm, Noggle and
# Pterosaur, aren't in story mode.)
DRAWN_BY_VAL = {"Viper", "Goblin", "Termites", "Charger", "Lightning Elemental", "Snowman"}

STAND_IN = "Assets/Textures/leeta-256x256.svg"  # the Leetha logo, used for two enemies


def scene_icon(scene_path):
    """The enemy_icon_texture a puzzle scene uses ("Assets/Textures/robot.png"), or ""."""
    path = scene_path.replace("res://", "")
    if not os.path.exists(path):
        return ""
    text = open(path, encoding="utf-8", errors="ignore").read()
    found = re.search(r'enemy_icon_texture = ExtResource\("([^"]+)"\)', text)
    if not found:
        return ""
    rid = re.escape(found.group(1))
    res = re.search(r'\[ext_resource[^\]]*path="([^"]+)"[^\]]*id="%s"' % rid, text) \
        or re.search(r'\[ext_resource[^\]]*id="%s"[^\]]*path="([^"]+)"' % rid, text)
    return res.group(1).replace("res://", "") if res else ""


def load_rows():
    story = json.load(open("Data/story_worlds.json", encoding="utf-8"))
    rows = []
    for number, world in enumerate(story["worlds"], 1):
        count = len(world["puzzles"])
        for at, puzzle in enumerate(world["puzzles"], 1):
            pid = puzzle["id"]
            kind = pid.split(":")[0] if pid.startswith(("url:", "story:")) else "scene"
            art = scene_icon(pid) if kind == "scene" else ""
            rows.append({"world_number": number, "world": world["name"], "at": at, "count": count,
                         "boss": at == count, "enemy": puzzle.get("enemy", "?"), "kind": kind,
                         "art": "" if art == STAND_IN else art, "stand_in": art == STAND_IN})
    return rows


SKULL = ('<svg class="boss" viewBox="0 0 24 24" aria-label="boss" role="img"><path d="M12 2C7 2 3.5 5.6 3.5 10.2'
         'c0 2.7 1.2 4.6 3 5.8V19a1 1 0 0 0 1 1h1.3v-2h1.4v2h3.6v-2h1.4v2h1.3a1 1 0 0 0 1-1v-3c1.8-1.2 3-3.1 3-5.8'
         'C20.5 5.6 17 2 12 2Zm-3.3 11.2a2.1 2.1 0 1 1 0-4.2 2.1 2.1 0 0 1 0 4.2Zm6.6 0a2.1 2.1 0 1 1 0-4.2 2.1 2.1 0 '
         '0 1 0 4.2Z"/></svg>')

STYLE = """
@font-face { font-family: "Quicksand"; src: url("/Assets/Fonts/Quicksand/static/Quicksand-Medium.ttf") format("truetype"); font-weight: 500; }
@font-face { font-family: "Quicksand"; src: url("/Assets/Fonts/Quicksand/static/Quicksand-Bold.ttf") format("truetype"); font-weight: 700; }
/* Every story enemy still to draw, A to Z, in one grid. A filled circle is today's art (click for the file); a dashed empty circle has no art yet. */
:root {
  --bg: #0d1412;
  --panel: #131d1a;
  --line: #22302c;
  --ring: #3a4a44;
  --gold: #ffce4e;
  --name: #e9eee9;
  --muted: #7d8f88;
  --blood: #c43335;
  --font: "Quicksand", "Segoe UI", system-ui, sans-serif;
  color-scheme: dark;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--name);
  font-family: var(--font);
  padding-block: 32px 48px;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
}
main { max-width: 1080px; margin: 0 auto; display: grid; gap: 28px; }
h2 {
  display: flex; align-items: center; gap: 10px;
  margin: 0 0 14px; font-size: 13px; font-weight: 700;
  letter-spacing: .14em; text-transform: uppercase; color: var(--muted);
}
.num {
  display: inline-grid; place-items: center; width: 24px; height: 24px;
  border-radius: 50%; background: var(--line); color: var(--gold);
  font-size: 12px; letter-spacing: 0; font-variant-numeric: tabular-nums;
}
ul {
  list-style: none; margin: 0; padding: 0;
  display: grid; grid-template-columns: repeat(auto-fill, minmax(118px, 1fr)); gap: 18px 12px;
}
.slot { display: grid; justify-items: center; gap: 10px; min-width: 0; text-align: center; }
.ring {
  width: 96px; height: 96px; max-width: 100%; aspect-ratio: 1;
  border-radius: 50%; background: var(--panel);
  border: 3px dashed var(--ring);
  display: grid; place-items: center; overflow: hidden;
}
.ring.art { border: 3px solid var(--ring); background: #e8e2cf; }
.ring.art:hover, .ring.art:focus-visible { border-color: var(--gold); outline: none; }
.ring img { width: 100%; height: 100%; object-fit: contain; display: block; }
.is-boss .ring { border-color: var(--gold); border-style: solid; }
.boss { width: 30px; height: 30px; fill: var(--blood); }
.name { font-size: 15px; font-weight: 700; line-height: 1.25; overflow-wrap: anywhere; }
.is-boss .name { color: var(--gold); }
@media (max-width: 420px) {
  ul { grid-template-columns: repeat(3, 1fr); }
  .ring { width: 78px; height: 78px; }
  .name { font-size: 13px; }
}
"""


def build_page(rows):
    """One grid of every enemy still to draw, A to Z: today's art (click for the file), or an empty circle."""
    todo = sorted((r for r in rows if r["enemy"] not in DRAWN_BY_VAL), key=lambda r: r["enemy"].lower())
    tiles = []
    for row in todo:
        enemy = html.escape(row["enemy"])
        if row["art"]:
            url = "/" + row["art"]
            ring = '<a class="ring art" href="%s" target="_blank" rel="noopener"><img src="%s" alt="%s" loading="lazy"></a>' % (url, url, enemy)
        else:
            ring = '<span class="ring"></span>'
        tiles.append('<li class="slot">%s<span class="name">%s</span></li>' % (ring, enemy))
    page = ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1">\n<meta name="robots" content="noindex">\n'
            '<title>Enemy Portraits - Lethal</title>\n<link rel="icon" href="/Assets/Textures/letha-180x180.png" type="image/png">\n'
            '<style>' + STYLE + '</style>\n</head>\n<body>\n<main>\n<ul>' + "".join(tiles) + '</ul>\n</main>\n</body>\n</html>\n')
    os.makedirs("art-refactor", exist_ok=True)
    open("art-refactor/index.html", "w", encoding="utf-8", newline="\n").write(page)
    return len(todo)


def build_inventory(rows):
    todo_new = [r for r in rows if not r["art"] and r["enemy"] not in DRAWN_BY_VAL]
    todo_redraw = [r for r in rows if r["art"] and r["enemy"] not in DRAWN_BY_VAL]
    done = [r for r in rows if r["enemy"] in DRAWN_BY_VAL]

    def where(r):
        return "puzzle %d of %d%s" % (r["at"], r["count"], ", boss" if r["boss"] else "")

    lines = ["# Story mode enemy art inventory", "",
             "Every enemy in story mode (Data/story_worlds.json) and the art it has today. Built by "
             "`python Tools/build_art_refactor.py`; the page for Val is playlethal.fun/art-refactor.", "",
             "- **%d need new art**: no picture of their own today (story-made and released URL puzzles show the "
             "generic placeholder; Wolverine and Carnivorous Plant use the Leetha logo as a stand-in)." % len(todo_new),
             "- **%d to redraw** in Val's style (older released puzzles with art in `Assets/Textures/`)." % len(todo_redraw),
             "- **%d already drawn by Val**: %s." % (len(done), ", ".join(sorted(r["enemy"] for r in done))), "",
             "## Needs new art (%d)" % len(todo_new), ""]
    by_world = collections.OrderedDict()
    for r in todo_new:
        by_world.setdefault((r["world_number"], r["world"]), []).append(r)
    for (number, name), items in by_world.items():
        lines.append("**World %d: %s** (%d)" % (number, name, len(items)))
        lines += ["- [ ] %s (%s)" % (r["enemy"], where(r)) for r in items]
        lines.append("")
    lines += ["## To redraw (%d)" % len(todo_redraw), "", "| World | Enemy | Puzzle | Current art |", "|---|---|---|---|"]
    lines += ["| %d. %s | %s | %s | `%s` |" % (r["world_number"], r["world"], r["enemy"], where(r), r["art"]) for r in todo_redraw]
    lines += ["", "## Already drawn by Val (%d)" % len(done), ""]
    lines += ["- [x] %s (world %d: %s, %s)" % (r["enemy"], r["world_number"], r["world"], where(r)) for r in done]
    open("Docs/story-enemy-art.md", "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    with open("Docs/story-enemy-art.csv", "w", encoding="utf-8", newline="") as f:
        out = csv.writer(f)
        out.writerow(["world_number", "world", "puzzle_in_world", "puzzles_in_world", "boss", "enemy", "puzzle_kind", "current_art", "status"])
        for r in rows:
            art = r["art"] or ("Leetha logo (stand-in)" if r["stand_in"] else "placeholder")
            status = "drawn by Val" if r["enemy"] in DRAWN_BY_VAL else ("redraw" if r["art"] else "new art")
            kind = {"story": "made for story", "url": "released daily (URL)", "scene": "released daily (scene)"}[r["kind"]]
            out.writerow([r["world_number"], r["world"], r["at"], r["count"], "yes" if r["boss"] else "", r["enemy"], kind, art, status])
    return len(todo_new), len(todo_redraw), len(done)


if __name__ == "__main__":
    rows = load_rows()
    missing = DRAWN_BY_VAL - {r["enemy"] for r in rows}
    if missing:
        print("Not in story mode (check the spelling):", ", ".join(sorted(missing)))
    shown = build_page(rows)
    new, redraw, done = build_inventory(rows)
    print("art-refactor/index.html: %d enemies (%d new art, %d to redraw); %d already drawn by Val" % (shown, new, redraw, done))
