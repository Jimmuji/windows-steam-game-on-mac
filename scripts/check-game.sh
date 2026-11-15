#!/bin/bash
# Look up a Steam game's supported platforms, Windows requirements and Steam Deck rating.
# Usage: ./scripts/check-game.sh <AppID>
# The AppID is the number in the store URL, e.g. 5088440 in store.steampowered.com/app/5088440/
set -euo pipefail

if [ $# -ne 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <Steam AppID>" >&2
  exit 1
fi
appid=$1

details=$(curl -fsS -m 20 "https://store.steampowered.com/api/appdetails?appids=${appid}&l=english&cc=us")
deck=$(curl -fsS -m 20 "https://store.steampowered.com/saleaction/ajaxgetdeckappcompatibilityreport?nAppID=${appid}" || echo '{}')

DETAILS="$details" DECK="$deck" APPID="$appid" /usr/bin/python3 -I - <<'PY'
import json, os, re

appid = os.environ["APPID"]
d = json.loads(os.environ["DETAILS"]).get(appid, {})
if not d.get("success"):
    raise SystemExit(f"AppID {appid} not found. Check the number.")
d = d["data"]

def text(html):
    html = re.sub(r"<br\s*/?>|</li>", "\n", html or "")
    html = re.sub(r"<[^>]+>", "", html)
    return "\n".join("    " + l.strip() for l in html.splitlines() if l.strip())

p = d.get("platforms", {})
print(f"Game:      {d.get('name')}  (AppID {appid})")
print(f"Released:  {d.get('release_date', {}).get('date', 'unknown')}")
print("Platforms: " + "  ".join(f"{k}:{'✔' if v else '✘'}" for k, v in p.items()))

if p.get("mac"):
    print("\n→ This game has a native Mac version. Install it with the Mac Steam client; you don't need this guide.")
elif not p.get("windows"):
    print("\n→ This game has no Windows version, so this guide can't help.")

pc = d.get("pc_requirements")
if isinstance(pc, dict):
    for key, label in (("minimum", "Windows minimum requirements"), ("recommended", "Windows recommended requirements")):
        if pc.get(key):
            print(f"\n{label}:\n{text(pc[key])}")

try:
    cat = json.loads(os.environ["DECK"]).get("results", {}).get("resolved_category", 0)
except Exception:
    cat = 0
label = {0: "Unknown / not tested", 1: "Unsupported", 2: "Playable", 3: "Verified"}.get(cat, f"Unknown ({cat})")
print(f"\nSteam Deck rating: {label}")
if cat in (2, 3):
    print("  → Runs under Proton (also Wine-based), so it has a good chance of working with Sikarugir.")
elif cat == 1:
    print("  → Doesn't run under Proton, so it probably won't work with Sikarugir either (often due to anti-cheat).")
PY
