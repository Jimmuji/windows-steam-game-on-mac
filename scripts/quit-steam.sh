#!/bin/bash
# Force-quit the Windows Steam client inside a Sikarugir wrapper.
#
# To quit normally, click "Steam" → "Exit" at the top left of the Steam window.
# Clicking the red × only hides Steam; quitting the wrapper from the Dock only closes the shell.
# Steam's command-line exit options (-shutdown, steam://exit) did nothing under Wine in testing,
# so this script kills every Wine process in the wrapper. Steam verifies its files on the next launch; that's normal.
#
# Usage:
#   ./scripts/quit-steam.sh                       # defaults to ~/Applications/Sikarugir/steam.app; asks first
#   ./scripts/quit-steam.sh --force               # no confirmation
#   ./scripts/quit-steam.sh [--force] path/to/steam.app
set -uo pipefail

force=0
if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]; then
  force=1
  shift
fi

w="${1:-$HOME/Applications/Sikarugir/steam.app}"
w="${w%/}"
S="$w/Contents/SharedSupport"

if [ ! -x "$S/wine/bin/wineserver" ]; then
  echo "Can't find $w, or it isn't a Sikarugir wrapper." >&2
  exit 1
fi

# Use the same environment the wrapper launches with, or wineserver can't find its bundled libraries
export WINEPREFIX="$S/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$S/wine/lib:$S/wine/lib64:$w/Contents/Frameworks"
export WINEDEBUG=-all

# Count processes instead of grep -q: it exits on the first match, and with pipefail that can turn "running" into "not running"
count() { ps -axww -o args= | grep -F -- "$1" | grep -vc grep; }
# wineserver manages every Windows process in this wrapper; once it's gone, everything is closed
wine_running()  { [ "$(count "$S/wine/")" -gt 0 ]; }
steam_running() { [ "$(count 'Steam\steam.exe')" -gt 0 ]; }

if ! wine_running; then
  echo "✔ Steam isn't running."
  exit 0
fi

if steam_running; then
  echo "Steam is running. It's better to quit normally first: click \"Steam\" → \"Exit\" in the Steam window."
else
  echo "Steam has exited, but Wine processes are still running in $(basename "$w")."
fi

if [ "$force" -ne 1 ]; then
  if [ ! -t 0 ]; then
    echo "To force-quit, run again with --force." >&2
    exit 1
  fi
  read -r -p "Force-quit now? [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 1 ;;
  esac
fi

echo "→ Killing all Wine processes in $(basename "$w")…"
"$S/wine/bin/wineserver" -k
for _ in $(seq 1 10); do
  if ! wine_running; then
    echo "✔ All closed."
    exit 0
  fi
  sleep 1
done
echo "✘ Some processes are still running. Search for \"wine\" in Activity Monitor and quit them manually." >&2
exit 1
