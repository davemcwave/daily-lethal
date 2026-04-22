"""
Post today's Daily Lethal puzzle to the Discord forum channel.

Reads the puzzle entry for today's UTC date from custom-redirects.json,
extracts enemy_name + author, and creates a forum thread with the site
image attached.

Uses the Python standard library only.

Env:
    DISCORD_BOT_TOKEN  (required) — bot token for the Daily Lethal bot

Usage:
    python post_daily_puzzle.py
"""

from __future__ import annotations

import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────
CHANNEL_ID = "1369845266613669899"         # Daily Lethal forum channel
ROLE_ID    = "1380329018892619806"         # @Lethal Enjoyers role
SITE_BASE  = "https://playlethal.fun"
# ─────────────────────────────────────────────────────────────────────────────

REPO_ROOT      = Path(__file__).resolve().parent
REDIRECTS_FILE = REPO_ROOT / "custom-redirects.json"
IMAGE_FILE     = REPO_ROOT / "Assets" / "Textures" / "leetha-256x256.png"

API_BASE = "https://discord.com/api/v10"


def load_puzzle_params(date_key: str) -> dict | None:
    """Return the parsed query params for today, or None if no entry exists."""
    data = json.loads(REDIRECTS_FILE.read_text(encoding="utf-8"))
    redirects = data.get("date_redirects", data)
    target = redirects.get(date_key)
    if not target:
        return None
    qs = target.lstrip("?").split("?", 1)[-1]
    parsed = urllib.parse.parse_qs(qs, keep_blank_values=True)
    return {k: v[0] for k, v in parsed.items()}


def build_post(date_key: str, enemy_name: str, author: str) -> tuple[str, str]:
    puzzle_url = f"{SITE_BASE}/{date_key}/"
    title = f"{date_key} {enemy_name}"[:100]  # Discord thread name max 100
    content = (
        f"Fight the [{enemy_name}]({puzzle_url})! <@&{ROLE_ID}>\n\n"
        f"Thank you {author}."
    )
    return title, content


def post_forum_thread(token: str, title: str, content: str, image_path: Path, *, ping_role: bool = False) -> dict:
    url = f"{API_BASE}/channels/{CHANNEL_ID}/threads"
    boundary = "----DailyLethalBoundary7f3a"

    allowed_mentions = {"parse": [], "roles": [ROLE_ID] if ping_role else []}
    payload = {
        "name": title,
        "message": {
            "content": content,
            "allowed_mentions": allowed_mentions,
            "attachments": [{"id": 0, "filename": image_path.name}],
        },
    }

    image_bytes = image_path.read_bytes()
    head = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="payload_json"\r\n'
        f"Content-Type: application/json\r\n\r\n"
        f"{json.dumps(payload)}\r\n"
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="files[0]"; filename="{image_path.name}"\r\n'
        f"Content-Type: image/png\r\n\r\n"
    ).encode("utf-8")
    tail = f"\r\n--{boundary}--\r\n".encode("utf-8")
    body = head + image_bytes + tail

    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bot {token}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "User-Agent": "DiscordBot (https://github.com/davemcwave/daily-lethal, 1.0)",
        },
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def main() -> int:
    ping_role = "--ping" in sys.argv

    token = os.environ.get("DISCORD_BOT_TOKEN")
    if not token:
        print("DISCORD_BOT_TOKEN env var is not set", file=sys.stderr)
        return 1

    date_key = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    params = load_puzzle_params(date_key)
    if not params:
        print(f"No puzzle entry for {date_key} in custom-redirects.json; skipping.")
        return 0

    enemy_name = params.get("enemy_name", "Unknown").strip()
    author = params.get("author", "Unknown").strip()
    if not enemy_name or not author:
        print(f"Missing enemy_name or author for {date_key}; skipping.", file=sys.stderr)
        return 1

    title, content = build_post(date_key, enemy_name, author)

    try:
        result = post_forum_thread(token, title, content, IMAGE_FILE, ping_role=ping_role)
    except urllib.error.HTTPError as e:
        print(f"Discord API error {e.code}: {e.read().decode(errors='replace')}", file=sys.stderr)
        return 1

    print(f"Posted thread {result.get('id')}: {title}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
