# macDeskpin

> Pin todos, notes & reminders directly on your Mac desktop. A lightweight native macOS app for people who want a cleaner desktop and a clearer mind.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-green)

## Why macDeskpin

Your Mac desktop is the most-seen surface in your day — but most todo apps hide behind a window or menubar icon. macDeskpin pins your tasks and notes **directly onto the desktop**, always visible, always one glance away.

- **Always-on-desktop**: notes live on the desktop layer, never blocking your work
- **Native & lightweight**: pure SwiftUI, no Electron, minimal RAM
- **Simple by design**: no accounts, no cloud, no subscription
- **Mac-first**: built for macOS 14+, Apple Silicon & Intel

## Features

- Pin todos and sticky notes to the desktop
- Drag to reposition, resize freely
- Auto-save, no setup required
- Clean Mac desktop, organize your day

## Install

1. Download the latest `.dmg` from [Releases](../../releases/latest)
2. Open the dmg and drag **DeskPin.app** to your **Applications** folder
3. **Run the one-line command below** to remove the macOS quarantine flag (see next section)
4. Launch DeskPin from Launchpad / Spotlight

### ⚠️ First launch on macOS — required one-time step

Because macDeskpin is **not yet notarized by Apple** (notarization requires a $99/year Apple Developer account), macOS Gatekeeper will refuse to open the app and show a misleading **"DeskPin is damaged and can't be opened"** message. The app is **not actually damaged** — this is macOS protecting you from unsigned downloads.

To allow the app to run, open **Terminal** and paste this single command:

```bash
sudo xattr -r -d com.apple.quarantine /Applications/DeskPin.app
```

It will ask for your Mac password (the same one you use to log in). Type it and press Enter — nothing will be printed if it succeeds. Then you can launch DeskPin normally from Launchpad.

**You only need to do this once**, after the very first install. Future updates may need it again.

**What this command does (plain English):** macOS attaches an invisible "quarantine" tag to anything you download from the internet. This command removes that tag from `DeskPin.app`, telling macOS "I trust this file." It does not change DeskPin itself, does not give DeskPin any extra power, and does not affect any other app on your system. The exact same command is recommended by many open-source Mac apps in the same situation (e.g. iina, NepTunes, Lyricsify).

If you'd rather not run a terminal command, you can instead [build from source](#build-from-source) — apps you build yourself are not quarantined.

## Build from source

```bash
git clone https://github.com/ZHLOVEYY/macDeskpin.git
cd macDeskpin
./build.sh        # swift build -c release
./package.sh      # produces dist/macDeskpin-<version>.dmg (ad-hoc signed)
```

Requirements: macOS 14+, Xcode 15+ / Swift 5.9.

## Roadmap

- [ ] Notarization & signed builds
- [ ] Multiple desktop spaces support
- [ ] Theme & font customization
- [ ] Markdown notes
- [ ] Auto-update via Sparkle

## License

[PolyForm Noncommercial License 1.0.0](./LICENSE).

You may use, copy, modify, and share macDeskpin for **any noncommercial purpose**. Commercial use is **not permitted** without a separate license from the author. See `LICENSE` for the full terms.

## Author

Built by [@harrymonkeyexe](https://harrymonkeyexe.com) — an indie OPC experiment.
