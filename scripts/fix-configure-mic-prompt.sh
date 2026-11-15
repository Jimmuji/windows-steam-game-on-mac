#!/bin/bash
# 修复 Sikarugir 的 “Configure would like to access the Microphone” 无限弹窗
# （https://github.com/Sikarugir-App/Sikarugir/issues/292）。
#
# 原因：wrapper 里的 Configure.app 签名不完整，macOS 无法记住授权结果。
# 做法：备份 Configure.app，然后对它做 ad-hoc 签名。只改动 wrapper 里的 Configure.app。
#
# 用法:
#   ./scripts/fix-configure-mic-prompt.sh                 # 处理 ~/Applications/Sikarugir 下所有 wrapper
#   ./scripts/fix-configure-mic-prompt.sh path/to/x.app   # 只处理指定的 wrapper（可以写多个）
set -euo pipefail

if [ $# -gt 0 ]; then
  wrappers=("$@")
else
  shopt -s nullglob
  wrappers=("$HOME/Applications/Sikarugir/"*.app)
fi

if [ ${#wrappers[@]} -eq 0 ]; then
  echo "在 ~/Applications/Sikarugir 里没找到 wrapper。可以直接把 wrapper 路径作为参数传进来。" >&2
  exit 1
fi

for w in "${wrappers[@]}"; do
  w="${w%/}"
  name=$(basename "$w")
  c="$w/Contents/Configure.app"

  if [ ! -d "$c" ]; then
    echo "跳过 $name：里面没有 Configure.app，不像是 Sikarugir wrapper"
    continue
  fi
  # 不用 grep -q：它提前退出时，配合 pipefail 可能把“在运行”误判成“没运行”
  if [ "$(ps -axww -o args= | grep -F -- "$w/Contents/" | grep -vc grep)" -gt 0 ]; then
    echo "跳过 $name：它正在运行。请先在 Steam 里点 Steam → Exit，并关掉 Configure 窗口后再试。"
    continue
  fi
  if codesign --verify --deep --strict "$c" 2>/dev/null; then
    echo "✔ $name：Configure.app 签名已经有效，无需处理"
    continue
  fi

  backup="${w%.app}-Configure.app.bak"
  if [ ! -e "$backup" ]; then
    cp -cR "$c" "$backup" 2>/dev/null || cp -R "$c" "$backup"
    echo "  已备份到 $backup"
  fi

  xattr -dr com.apple.quarantine "$c" 2>/dev/null || true
  codesign --force --deep -s - "$c"
  if codesign --verify --deep --strict "$c"; then
    echo "✔ $name：Configure.app 已重新签名。下次弹窗时选一次 Allow 或 Don't Allow，系统就会记住了。"
  else
    echo "✘ $name：签名后校验失败，可以用备份恢复：rm -rf \"$c\" && mv \"$backup\" \"$c\"" >&2
    exit 1
  fi
done
