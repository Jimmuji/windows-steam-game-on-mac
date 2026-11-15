#!/bin/bash
# 检查这台 Mac 是否适合用 Sikarugir 运行 Windows 游戏。
# 只读取信息，不修改任何东西。
set -u

if [ -t 1 ]; then G=$'\033[32m' Y=$'\033[33m' R=$'\033[31m' N=$'\033[0m'; else G= Y= R= N=; fi
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
bad()  { printf '  %s✘%s %s\n' "$R" "$N" "$*"; }

echo "== 硬件"
chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
arch=$(uname -m)
mem_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
echo "  芯片: $chip ($arch)"
echo "  内存: ${mem_gb} GB"
if [ "$arch" = "arm64" ]; then
  ok "Apple Silicon，可以使用 D3DMetal"
else
  warn "Intel Mac：D3DMetal 不可用，只能用 DXVK / DXMT 等其他渲染器"
fi
[ "$mem_gb" -ge 16 ] && ok "内存充足" || warn "内存不足 16 GB，转译后吃力的游戏可能会卡"

echo "== 系统"
os=$(sw_vers -productVersion)
echo "  macOS $os"
major=${os%%.*}
if [ "$major" -ge 15 ] || { [ "$major" -eq 14 ] && [ "$(echo "$os" | cut -d. -f2)" -ge 6 ]; }; then
  ok "满足 Sikarugir 最低要求（macOS 14.6）"
else
  bad "Sikarugir 需要 macOS 14.6 或更新版本"
fi

echo "== 磁盘"
free=$(df -h / | awk 'NR==2 {print $4}')
echo "  系统盘剩余: $free"

echo "== 依赖"
if [ "$arch" = "arm64" ]; then
  if /usr/bin/pgrep -q oahd || [ -e /Library/Apple/usr/libexec/oah/libRosettaRuntime ]; then
    ok "Rosetta 2 已安装"
  else
    bad "Rosetta 2 未安装：/usr/sbin/softwareupdate --install-rosetta --agree-to-license"
  fi
fi

brew_bin=$(command -v brew || ls /opt/homebrew/bin/brew /usr/local/bin/brew 2>/dev/null | head -1)
if [ -n "$brew_bin" ]; then
  ok "Homebrew: $("$brew_bin" --version 2>/dev/null | head -1)"
else
  warn "Homebrew 未安装（见 README 第 1 步）"
fi

creator="/Applications/Sikarugir Creator.app"
if [ -d "$creator" ]; then
  v=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$creator/Contents/Info.plist" 2>/dev/null)
  ok "Sikarugir Creator $v"
else
  warn "Sikarugir Creator 未安装（见 README 第 2 步）"
fi

wrappers=$(ls -d "$HOME/Applications/Sikarugir/"*.app 2>/dev/null)
if [ -n "$wrappers" ]; then
  echo "== 已有的 wrapper"
  while IFS= read -r w; do
    plist="$w/Contents/Info.plist"
    prog=$(/usr/libexec/PlistBuddy -c "Print :'Program Name and Path'" "$plist" 2>/dev/null)
    d3d=$(/usr/libexec/PlistBuddy -c "Print :D3DMETAL" "$plist" 2>/dev/null)
    echo "  $(basename "$w")  →  ${prog:-（未设置启动程序）}  D3DMetal=${d3d:-?}"
  done <<< "$wrappers"
fi
