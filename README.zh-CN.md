# Windows Steam Game on Mac

[English](README.md) | **简体中文**

在 Apple Silicon Mac 上，用**免费**的 [Sikarugir](https://github.com/Sikarugir-App/Sikarugir) 运行**只有 Windows 版**的 Steam 游戏。本仓库是一份实操记录，附带几个排错用的小脚本。

---

## 测试环境

| 项目 | 版本 |
|---|---|
| 电脑 | MacBook Pro，Apple M5 Pro，24 GB 内存 |
| 系统 | macOS 26.5.1 |
| Homebrew | 7.0.12 |
| Sikarugir Creator | 1.0.2 |
| Wrapper 模板 | Template 1.0.27 |
| 引擎 | `WS12WineSikarugir11.0_1`（Wine 11.0） |
| 图形转译 | D3DMetal |
| 时间 | 2026 年 11 月 |

**结果**

| 软件 | 状态 |
|---|---|
| Windows 版 Steam 客户端 | ✅ 能登录、浏览商店、下载游戏 |
| Rip It! Card Collector（再拆亿包！，AppID 5088440） | ✅ 能正常游玩（D3DMetal） |

---

## 先判断：你的 Mac 和游戏合不合适

```bash
./scripts/check-mac.sh            # 芯片、内存、系统、Rosetta、Homebrew、Sikarugir 状态
./scripts/check-game.sh 5088440   # 游戏支持哪些平台、Windows 配置要求、Steam Deck 评级
```

- 游戏页面写着只支持 Windows，Mac 版 Steam 就装不了它，需要用转译层（Wine）。
- **Steam Deck 评级是个很好的参考**：Steam Deck 用的 Proton 和 Sikarugir 底层都是 Wine。评级是“已验证 / 可玩”的游戏，在 Mac 上成功的概率更高（但不保证）。
- 有反作弊（如 EAC、BattlEye、Vanguard）的网游基本跑不了，单机游戏最合适。
- Steam 支持购买 14 天内、游戏时长不到 2 小时的退款，跑不起来也不会白花钱。

---

## 安装步骤

### 1. 安装 Homebrew 和 Rosetta 2

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

需要输入开机密码，中途还要按一次回车。装完按提示把 brew 加入 PATH：

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

Apple Silicon 还需要 Rosetta 2（`check-mac.sh` 会告诉你装没装）：

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

### 2. 安装 Sikarugir

```bash
brew trust Sikarugir-App/sikarugir
brew install --cask Sikarugir-App/sikarugir/sikarugir
```

> ⚠️ **只从 GitHub 或 Homebrew 安装。** 官方 README 提醒：`sikarugir.com` **不是**官方网站。

### 3. 创建一个装 Steam 的 wrapper

打开“应用程序”里的 **Sikarugir Creator**：

1. 点 **Download Template x.x.x**，下载最新模板。
2. 点 **Change** 选引擎，选列表最上面的 **`WS12WineSikarugir11.0_1`**（最新的那个）。
   - `WS11` 开头是旧系列，`32Bit` 是 32 位，都不选。
   - 如果 Steam 登录界面黑屏或卡住，可以换 `WS12WineCX24.0.7_7`（基于 CrossOver）再建一个试试。
3. 点 **Create**，名字填 `steam`，保存到默认的 `Sikarugir` 文件夹（`~/Applications/Sikarugir/`）。

### 4. 在 wrapper 里安装 Windows 版 Steam

先从 [Steam 官网](https://store.steampowered.com/about/)下载 **Windows 版**安装程序 `SteamSetup.exe`。这是安装程序，**不用解压，也不要双击**。

在弹出的 **Configure** 窗口里：

1. 勾选 **Direct3D to Metal translation layer - (D3DMetal)**。
2. 点 **Install Software**，选 `SteamSetup.exe`。
3. 安装向导里语言先选 **English**（原因见下面的排错）。路径保持默认 `C:\Program Files (x86)\Steam`，不要改。
4. 确认 **Windows app** 一栏是 `"C:\Program Files (x86)\Steam\steam.exe"`，不是的话点 **Browse** 手动选。

### 5. 启动

**在“访达 → 应用程序 → Sikarugir”里双击 `steam.app`**，不要用 Configure 里的 Test Run（原因见下面的排错）。第一次启动会先自动更新，然后登录、购买、下载游戏即可。

> 你的 Mac 上可能同时装着 **Mac 版 Steam**（`/Applications/Steam.app`），它装不了只有 Windows 版的游戏。别点错，用 Sikarugir 里那个。

---

## 排错

### 创建 wrapper 时报错 “wswine.bundle couldn't be removed…”

可以忽略。这只是清理临时文件失败，wrapper 本身已经建好了。在 `~/Applications/Sikarugir/` 里能看到 `steam.app` 就没问题。

### 安装 Steam 时提示 “No new executables found! Maybe the installer failed…”

提示弹早了：安装向导还开着，Sikarugir 就以为安装已经结束，去检查了。点 OK，继续走完 Steam 安装向导就行。

### 安装语言列表里中文显示成 □□□□

Wine 里还没有中文字体，第一列最上面两个 `□□□□` 分别是简体中文和繁體中文。建议**先选 English**。之后在 Configure 里点 **Winetricks**，安装 `cjkfonts`，再到 Steam 的 Settings → Interface 里改成中文。

### “Configure would like to access the Microphone” 无限弹窗

已知问题：[Sikarugir-App/Sikarugir#292](https://github.com/Sikarugir-App/Sikarugir/issues/292)。

- 原因：wrapper 里的 `Configure.app` 签名不完整，macOS 记不住你的选择。Steam 每启动一个子进程，Wine 就会初始化一次音频，于是又弹一次。
- 只有从 Configure 里启动（Test Run、Install Software、winecfg）时才会出现。**正常双击 wrapper 启动不会。**
- 修复：先关掉 Steam 和 Configure，再运行：

```bash
./scripts/fix-configure-mic-prompt.sh                      # 处理 ~/Applications/Sikarugir 下所有 wrapper
./scripts/fix-configure-mic-prompt.sh ~/Applications/Sikarugir/steam.app   # 只处理一个
```

脚本会先备份 `Configure.app`，再做 ad-hoc 签名。wrapper 本身（`steam.app`）没法这样签名，因为它的主程序 `launcher` 是符号链接，不过它本来也不受这个问题影响。

### Steam 关不掉，“一关就自动打开”

Steam 并没有自动重启：

- 点窗口的红色 × 只是**把窗口藏起来**，Steam 继续在后台运行（在 Windows 上是缩到托盘）。
- 在程序坞里退出 `steam.app`，只关掉 Sikarugir 的外壳，里面的 Windows 版 Steam 还在跑。

**正确的关法：在 Steam 窗口左上角点 “Steam” 菜单 → “Exit”。**

如果菜单点不了，或者退出后还有 Wine 进程残留，可以强制关闭：

```bash
./scripts/quit-steam.sh            # 默认 ~/Applications/Sikarugir/steam.app，会先问你确认
./scripts/quit-steam.sh --force    # 不确认，直接关闭
```

注意：Steam 的命令行退出方式（`-shutdown`、`steam://exit`）在 Wine 里实测都没用，所以脚本是直接结束这个 wrapper 里的所有 Wine 进程。下次启动时 Steam 会先自检一下文件，这是正常的。不要在游戏存档或下载过程中强制关闭。

---

## 其他方案对比

| 方案 | 费用 | 状态（2026-11） | 说明 |
|---|---|---|---|
| **Sikarugir** | 免费 | ✅ 活跃维护 | 本指南用的方案。Wineskin / Kegworks 的后继者，需要自己动手 |
| CrossOver | 付费，有 14 天试用 | ✅ 商业维护 | 最省事，Steam 兼容性通常最好 |
| Parallels + Windows 11 ARM | 订阅费 + Windows 授权 | ✅ | 兼容性稳，但资源占用大 |
| Whisky | 免费 | ❌ 2025 年已归档 | 停止维护，不推荐 |
| Mythic | 免费 | ⚠️ 测试版 | 主要支持 Epic，Steam 支持还没做完 |
| UTM | 免费 | ✅ | Windows 虚拟机没有 3D 加速，跑不了 3D 游戏 |

**关于“开源”：** Sikarugir 不是完全开源。根据它的 README，只有 `Configure.app`（由 Wineskin 修改而来）是 LGPL-2.1；新版 Creator 和启动器不在 LGPL 范围内。D3DMetal 是苹果的闭源组件，许可证不允许商用移植，但个人玩游戏没问题。

---

## 脚本一览

| 脚本 | 作用 |
|---|---|
| [`scripts/check-mac.sh`](scripts/check-mac.sh) | 查看芯片、内存、系统版本、磁盘空间、Rosetta / Homebrew / Sikarugir 是否已安装 |
| [`scripts/check-game.sh`](scripts/check-game.sh) | 根据 Steam AppID 查询游戏的平台支持、Windows 配置要求和 Steam Deck 评级 |
| [`scripts/fix-configure-mic-prompt.sh`](scripts/fix-configure-mic-prompt.sh) | 备份并重新签名 wrapper 里的 `Configure.app`，解决麦克风无限弹窗 |
| [`scripts/quit-steam.sh`](scripts/quit-steam.sh) | 正常退出不管用时，强制关闭 wrapper 里的 Windows 版 Steam |

所有脚本只读写你自己的 wrapper，不修改系统设置。脚本的输出是英文。

---

## 致谢

- [Gcenx](https://github.com/Gcenx) 和 [Sikarugir-App](https://github.com/Sikarugir-App) 团队维护 Sikarugir 和 Wine 引擎
- [Wine](https://www.winehq.org/) 项目
- Valve 的 [Proton](https://github.com/ValveSoftware/Proton) 和 Steam Deck 兼容性评级

## 许可证

本仓库的文档和脚本以 [MIT](LICENSE) 许可发布。Sikarugir、Wine、Steam 和 D3DMetal 各自遵循其原有许可。本仓库不包含它们的任何文件。
