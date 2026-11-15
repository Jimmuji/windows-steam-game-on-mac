# Windows Steam Game on Mac

**English** | [简体中文](README.zh-CN.md)

Run **Windows-only** Steam games on an Apple Silicon Mac with the **free** [Sikarugir](https://github.com/Sikarugir-App/Sikarugir) wrapper (the successor of Wineskin / Kegworks) and Apple's D3DMetal. This repo is a hands-on record of a working setup, plus a few small helper scripts for troubleshooting.

---

## Test environment

| Item | Version |
|---|---|
| Computer | MacBook Pro, Apple M5 Pro, 24 GB RAM |
| OS | macOS 26.5.1 |
| Homebrew | 7.0.12 |
| Sikarugir Creator | 1.0.2 |
| Wrapper template | Template 1.0.27 |
| Engine | `WS12WineSikarugir11.0_1` (Wine 11.0) |
| Graphics translation | D3DMetal |
| Date | November 2026 |

**Results**

| Software | Status |
|---|---|
| Steam client (Windows version) | ✅ Logs in, browses the store, downloads games |
| Rip It! Card Collector (AppID 5088440) | ✅ Fully playable (D3DMetal) |

---

## First: is your Mac (and the game) a good fit?

```bash
./scripts/check-mac.sh            # chip, RAM, macOS, Rosetta, Homebrew, Sikarugir status
./scripts/check-game.sh 5088440   # supported platforms, Windows requirements, Steam Deck rating
```

- If the store page lists Windows only, the Mac version of Steam can't install the game. You need a translation layer (Wine).
- **The Steam Deck rating is a good hint.** Steam Deck's Proton and Sikarugir are both built on Wine. Games rated "Verified" or "Playable" are more likely to work on a Mac (not guaranteed).
- Online games with anti-cheat (EAC, BattlEye, Vanguard, etc.) usually won't run. Single-player games are the best fit.
- Steam refunds purchases within 14 days and under 2 hours of playtime, so you don't lose money if a game doesn't run.

---

## Installation

### 1. Install Homebrew and Rosetta 2

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

It asks for your login password and for Return once. When it finishes, add brew to your PATH as instructed:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

Apple Silicon also needs Rosetta 2 (`check-mac.sh` tells you whether it's installed):

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

### 2. Install Sikarugir

```bash
brew trust Sikarugir-App/sikarugir
brew install --cask Sikarugir-App/sikarugir/sikarugir
```

> ⚠️ **Install only from GitHub or Homebrew.** The official README warns that `sikarugir.com` is **not** the official site.

### 3. Create a wrapper for Steam

Open **Sikarugir Creator** from Applications:

1. Click **Download Template x.x.x** to get the latest template.
2. Click **Change** and pick the engine at the top of the list, **`WS12WineSikarugir11.0_1`** (the newest one).
   - Engines starting with `WS11` are the older series, and `32Bit` ones are 32-bit. Skip both.
   - If the Steam login screen is black or hangs, try creating another wrapper with `WS12WineCX24.0.7_7` (based on CrossOver).
3. Click **Create**, name it `steam`, and save it to the default `Sikarugir` folder (`~/Applications/Sikarugir/`).

### 4. Install the Windows Steam client in the wrapper

Download the **Windows** installer `SteamSetup.exe` from the [Steam website](https://store.steampowered.com/about/). It's an installer: **don't unzip it, and don't double-click it**.

In the **Configure** window that opens:

1. Check **Direct3D to Metal translation layer - (D3DMetal)**.
2. Click **Install Software** and select `SteamSetup.exe`.
3. In the setup wizard, pick **English** as the language (see Troubleshooting for why). Keep the default path `C:\Program Files (x86)\Steam`.
4. Make sure the **Windows app** field is `"C:\Program Files (x86)\Steam\steam.exe"`. If not, click **Browse** and select it.

### 5. Launch

**Double-click `steam.app` in Finder → Applications → Sikarugir.** Don't use Test Run in Configure (see Troubleshooting). On first launch Steam updates itself; then log in, buy and download your game.

> Your Mac may also have the **Mac version of Steam** (`/Applications/Steam.app`). It can't install Windows-only games. Make sure you open the one in the Sikarugir folder.

---

## Troubleshooting

### "wswine.bundle couldn't be removed…" when creating the wrapper

Safe to ignore. Only the cleanup of a temporary file failed; the wrapper itself was created. If `steam.app` is in `~/Applications/Sikarugir/`, you're fine.

### "No new executables found! Maybe the installer failed…" while installing Steam

The check fires too early: Sikarugir thinks the installer has finished while the setup wizard is still open. Click OK and finish the Steam setup wizard.

### Chinese / Japanese / Korean text shows as □□□□

Wine has no CJK fonts yet. For example, the two `□□□□` entries at the top of the installer's language list are Simplified and Traditional Chinese. Pick **English** first. Then click **Winetricks** in Configure, install `cjkfonts`, and change the language in Steam under Settings → Interface.

### Endless "Configure would like to access the Microphone" prompt

Known issue: [Sikarugir-App/Sikarugir#292](https://github.com/Sikarugir-App/Sikarugir/issues/292).

- Cause: the wrapper's `Configure.app` has an incomplete code signature, so macOS can't remember your answer. Each time Steam starts a child process, Wine initializes audio again, and the prompt comes back.
- It only happens when Steam is started from Configure (Test Run, Install Software, winecfg). **Double-clicking the wrapper doesn't trigger it.**
- Fix: quit Steam and Configure, then run:

```bash
./scripts/fix-configure-mic-prompt.sh                      # every wrapper in ~/Applications/Sikarugir
./scripts/fix-configure-mic-prompt.sh ~/Applications/Sikarugir/steam.app   # just one
```

The script backs up `Configure.app`, then ad-hoc signs it. The wrapper itself (`steam.app`) can't be signed this way because its main executable `launcher` is a symlink, but it isn't affected by this issue anyway.

### Steam won't quit and "reopens by itself"

Steam isn't actually restarting:

- Clicking the red × only **hides the window**. Steam keeps running in the background (on Windows it would go to the tray).
- Quitting `steam.app` from the Dock only closes the Sikarugir shell. The Windows Steam client inside keeps running.

**To quit properly, click the "Steam" menu at the top left of the Steam window → "Exit".**

If the menu doesn't respond, or Wine processes are left over after exiting, force-quit:

```bash
./scripts/quit-steam.sh            # defaults to ~/Applications/Sikarugir/steam.app; asks first
./scripts/quit-steam.sh --force    # no confirmation
```

Note: Steam's command-line exit options (`-shutdown`, `steam://exit`) did nothing under Wine in testing, so the script kills every Wine process in that wrapper. Steam verifies its files on the next launch; that's normal. Don't force-quit while a game is saving or a download is in progress.

---

## Alternatives

| Option | Cost | Status (Nov 2026) | Notes |
|---|---|---|---|
| **Sikarugir** | Free | ✅ Actively maintained | Used in this guide. Successor of Wineskin / Kegworks; more hands-on |
| CrossOver | Paid, 14-day trial | ✅ Commercially maintained | Easiest; usually the best Steam compatibility |
| Parallels + Windows 11 ARM | Subscription + Windows license | ✅ | Solid compatibility, but heavy on resources |
| Whisky | Free | ❌ Archived in 2025 | No longer maintained; not recommended |
| Mythic | Free | ⚠️ Beta | Mainly targets Epic; Steam support is incomplete |
| UTM | Free | ✅ | Windows VMs have no 3D acceleration, so 3D games won't run |

**About "open source":** Sikarugir isn't fully open source. According to its README, only `Configure.app` (derived from Wineskin) is LGPL-2.1; the new Creator and launcher are not covered by the LGPL. D3DMetal is a closed-source Apple component whose license doesn't allow commercial ports, but playing games on your own Mac is fine.

---

## Scripts

| Script | What it does |
|---|---|
| [`scripts/check-mac.sh`](scripts/check-mac.sh) | Shows chip, RAM, macOS version, free disk space, and whether Rosetta / Homebrew / Sikarugir are installed |
| [`scripts/check-game.sh`](scripts/check-game.sh) | Looks up a game's platforms, Windows requirements and Steam Deck rating by Steam AppID |
| [`scripts/fix-configure-mic-prompt.sh`](scripts/fix-configure-mic-prompt.sh) | Backs up and re-signs the wrapper's `Configure.app` to stop the endless microphone prompt |
| [`scripts/quit-steam.sh`](scripts/quit-steam.sh) | Force-quits the Windows Steam client inside a wrapper when a normal exit doesn't work |

The scripts only read and write your own wrappers. They don't change system settings.

---

## Credits

- [Gcenx](https://github.com/Gcenx) and the [Sikarugir-App](https://github.com/Sikarugir-App) team for Sikarugir and its Wine engines
- The [Wine](https://www.winehq.org/) project
- Valve's [Proton](https://github.com/ValveSoftware/Proton) and the Steam Deck compatibility ratings

## License

The docs and scripts in this repo are released under the [MIT](LICENSE) license. Sikarugir, Wine, Steam and D3DMetal are under their own licenses. This repo contains none of their files.
