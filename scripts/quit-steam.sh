#!/bin/bash
# 强制关闭 Sikarugir wrapper 里的 Windows 版 Steam。
#
# 正常退出请在 Steam 窗口左上角点 “Steam” → “Exit”。
# 点窗口的红色 × 只会把 Steam 藏到后台；在程序坞里退出 wrapper 也只关掉外壳。
# Steam 的命令行退出方式（-shutdown、steam://exit）在 Wine 里实测无效，
# 所以这个脚本直接结束 wrapper 里的所有 Wine 进程。下次启动时 Steam 会先自检一下文件，属于正常现象。
#
# 用法:
#   ./scripts/quit-steam.sh                       # 默认 ~/Applications/Sikarugir/steam.app，会先确认
#   ./scripts/quit-steam.sh --force               # 不确认，直接关闭
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
  echo "找不到 $w，或者它不是 Sikarugir wrapper。" >&2
  exit 1
fi

# 用和 wrapper 启动时相同的环境，否则 wineserver 找不到自带的运行库
export WINEPREFIX="$S/prefix"
export DYLD_FALLBACK_LIBRARY_PATH="$S/wine/lib:$S/wine/lib64:$w/Contents/Frameworks"
export WINEDEBUG=-all

# 数进程时不用 grep -q：它找到第一行就退出，配合 pipefail 可能把“在运行”误判成“没运行”
count() { ps -axww -o args= | grep -F -- "$1" | grep -vc grep; }
# wineserver 是这个 wrapper 里所有 Windows 进程的“总管”，它退出就说明全部关完了
wine_running()  { [ "$(count "$S/wine/")" -gt 0 ]; }
steam_running() { [ "$(count 'Steam\steam.exe')" -gt 0 ]; }

if ! wine_running; then
  echo "✔ Steam 没有在运行。"
  exit 0
fi

if steam_running; then
  echo "Steam 正在运行。建议先在 Steam 窗口里点 “Steam” → “Exit” 正常退出。"
else
  echo "Steam 已经退出，但 $(basename "$w") 里还有 Wine 进程在运行。"
fi

if [ "$force" -ne 1 ]; then
  if [ ! -t 0 ]; then
    echo "要强制关闭，请加上 --force 重新运行。" >&2
    exit 1
  fi
  read -r -p "现在强制关闭吗？[y/N] " ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "已取消。"; exit 1 ;;
  esac
fi

echo "→ 结束 $(basename "$w") 里的所有 Wine 进程…"
"$S/wine/bin/wineserver" -k
for _ in $(seq 1 10); do
  if ! wine_running; then
    echo "✔ 已全部关闭。"
    exit 0
  fi
  sleep 1
done
echo "✘ 仍有进程没关掉，可以在“活动监视器”里搜索 wine 手动结束。" >&2
exit 1
