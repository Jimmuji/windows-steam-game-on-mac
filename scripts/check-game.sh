#!/bin/bash
# 查询 Steam 游戏的平台支持、Windows 配置要求和 Steam Deck 评级。
# 用法: ./scripts/check-game.sh <AppID>
# AppID 是商店链接里的数字，例如 store.steampowered.com/app/5088440/ 里的 5088440
set -euo pipefail

if [ $# -ne 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "用法: $0 <Steam AppID>" >&2
  exit 1
fi
appid=$1

details=$(curl -fsS -m 20 "https://store.steampowered.com/api/appdetails?appids=${appid}&l=schinese&cc=cn")
deck=$(curl -fsS -m 20 "https://store.steampowered.com/saleaction/ajaxgetdeckappcompatibilityreport?nAppID=${appid}" || echo '{}')

DETAILS="$details" DECK="$deck" APPID="$appid" /usr/bin/python3 -I - <<'PY'
import json, os, re

appid = os.environ["APPID"]
d = json.loads(os.environ["DETAILS"]).get(appid, {})
if not d.get("success"):
    raise SystemExit(f"找不到 AppID {appid}，请检查数字是否正确。")
d = d["data"]

def text(html):
    html = re.sub(r"<br\s*/?>|</li>", "\n", html or "")
    html = re.sub(r"<[^>]+>", "", html)
    return "\n".join("    " + l.strip() for l in html.splitlines() if l.strip())

p = d.get("platforms", {})
print(f"游戏: {d.get('name')}  (AppID {appid})")
print(f"发售: {d.get('release_date', {}).get('date', '未知')}")
print("平台: " + "  ".join(f"{k}:{'✔' if v else '✘'}" for k, v in p.items()))

if p.get("mac"):
    print("\n→ 这个游戏有 Mac 原生版，直接用 Mac 版 Steam 安装即可，不需要本指南。")
elif not p.get("windows"):
    print("\n→ 这个游戏没有 Windows 版，本指南帮不上忙。")

pc = d.get("pc_requirements")
if isinstance(pc, dict):
    for key, label in (("minimum", "Windows 最低配置"), ("recommended", "Windows 推荐配置")):
        if pc.get(key):
            print(f"\n{label}:\n{text(pc[key])}")

try:
    cat = json.loads(os.environ["DECK"]).get("results", {}).get("resolved_category", 0)
except Exception:
    cat = 0
label = {0: "未知 / 未测试", 1: "不支持", 2: "可玩", 3: "已验证"}.get(cat, f"未知 ({cat})")
print(f"\nSteam Deck 评级: {label}")
if cat in (2, 3):
    print("  → 在 Proton（同样基于 Wine）下能运行，用 Sikarugir 成功的希望较大。")
elif cat == 1:
    print("  → Proton 下无法运行，Sikarugir 大概率也不行（常见原因是反作弊）。")
PY
