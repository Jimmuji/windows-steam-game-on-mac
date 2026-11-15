#!/bin/bash
# Fix Sikarugir's endless "Configure would like to access the Microphone" prompt
# (https://github.com/Sikarugir-App/Sikarugir/issues/292).
#
# Cause: the wrapper's Configure.app has an incomplete code signature, so macOS can't remember your answer.
# Fix: back up Configure.app, then ad-hoc sign it. Only the wrapper's Configure.app is changed.
#
# Usage:
#   ./scripts/fix-configure-mic-prompt.sh                 # every wrapper in ~/Applications/Sikarugir
#   ./scripts/fix-configure-mic-prompt.sh path/to/x.app   # only the given wrapper(s)
set -euo pipefail

if [ $# -gt 0 ]; then
  wrappers=("$@")
else
  shopt -s nullglob
  wrappers=("$HOME/Applications/Sikarugir/"*.app)
fi

if [ ${#wrappers[@]} -eq 0 ]; then
  echo "No wrappers found in ~/Applications/Sikarugir. You can pass a wrapper path as an argument." >&2
  exit 1
fi

for w in "${wrappers[@]}"; do
  w="${w%/}"
  name=$(basename "$w")
  c="$w/Contents/Configure.app"

  if [ ! -d "$c" ]; then
    echo "Skipping $name: no Configure.app inside, doesn't look like a Sikarugir wrapper"
    continue
  fi
  # Not grep -q: it exits early, and with pipefail that can turn "running" into "not running"
  if [ "$(ps -axww -o args= | grep -F -- "$w/Contents/" | grep -vc grep)" -gt 0 ]; then
    echo "Skipping $name: it's running. In Steam, click Steam → Exit, close the Configure window, then try again."
    continue
  fi
  if codesign --verify --deep --strict "$c" 2>/dev/null; then
    echo "✔ $name: Configure.app already has a valid signature, nothing to do"
    continue
  fi

  backup="${w%.app}-Configure.app.bak"
  if [ ! -e "$backup" ]; then
    cp -cR "$c" "$backup" 2>/dev/null || cp -R "$c" "$backup"
    echo "  Backed up to $backup"
  fi

  xattr -dr com.apple.quarantine "$c" 2>/dev/null || true
  codesign --force --deep -s - "$c"
  if codesign --verify --deep --strict "$c"; then
    echo "✔ $name: Configure.app re-signed. Next time the prompt appears, choose Allow or Don't Allow once and macOS will remember it."
  else
    echo "✘ $name: verification failed after signing. Restore the backup with: rm -rf \"$c\" && mv \"$backup\" \"$c\"" >&2
    exit 1
  fi
done
