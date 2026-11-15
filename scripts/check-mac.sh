#!/bin/bash
# Check whether this Mac is a good fit for running Windows games with Sikarugir.
# Read-only: changes nothing.
set -u

if [ -t 1 ]; then G=$'\033[32m' Y=$'\033[33m' R=$'\033[31m' N=$'\033[0m'; else G= Y= R= N=; fi
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
bad()  { printf '  %s✘%s %s\n' "$R" "$N" "$*"; }

echo "== Hardware"
chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
arch=$(uname -m)
mem_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
echo "  Chip:   $chip ($arch)"
echo "  Memory: ${mem_gb} GB"
if [ "$arch" = "arm64" ]; then
  ok "Apple Silicon: D3DMetal is available"
else
  warn "Intel Mac: D3DMetal isn't available; only other renderers such as DXVK / DXMT"
fi
[ "$mem_gb" -ge 16 ] && ok "Enough memory" || warn "Less than 16 GB of memory; demanding games may stutter under translation"

echo "== System"
os=$(sw_vers -productVersion)
echo "  macOS $os"
major=${os%%.*}
if [ "$major" -ge 15 ] || { [ "$major" -eq 14 ] && [ "$(echo "$os" | cut -d. -f2)" -ge 6 ]; }; then
  ok "Meets Sikarugir's minimum (macOS 14.6)"
else
  bad "Sikarugir needs macOS 14.6 or later"
fi

echo "== Disk"
free=$(df -h / | awk 'NR==2 {print $4}')
echo "  Free on system disk: $free"

echo "== Dependencies"
if [ "$arch" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd || [ -e /Library/Apple/usr/libexec/oah/libRosettaRuntime ]; then
    ok "Rosetta 2 is installed"
  else
    bad "Rosetta 2 is not installed: /usr/sbin/softwareupdate --install-rosetta --agree-to-license"
  fi
fi

brew_bin=$(command -v brew || ls /opt/homebrew/bin/brew /usr/local/bin/brew 2>/dev/null | head -1)
if [ -n "$brew_bin" ]; then
  ok "Homebrew: $("$brew_bin" --version 2>/dev/null | head -1)"
else
  warn "Homebrew is not installed (see step 1 in the README)"
fi

creator="/Applications/Sikarugir Creator.app"
if [ -d "$creator" ]; then
  v=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$creator/Contents/Info.plist" 2>/dev/null)
  ok "Sikarugir Creator $v"
else
  warn "Sikarugir Creator is not installed (see step 2 in the README)"
fi

wrappers=$(ls -d "$HOME/Applications/Sikarugir/"*.app 2>/dev/null)
if [ -n "$wrappers" ]; then
  echo "== Existing wrappers"
  while IFS= read -r w; do
    plist="$w/Contents/Info.plist"
    prog=$(/usr/libexec/PlistBuddy -c "Print :'Program Name and Path'" "$plist" 2>/dev/null)
    d3d=$(/usr/libexec/PlistBuddy -c "Print :D3DMETAL" "$plist" 2>/dev/null)
    echo "  $(basename "$w")  →  ${prog:-(no program set)}  D3DMetal=${d3d:-?}"
  done <<< "$wrappers"
fi
