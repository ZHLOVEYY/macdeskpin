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

Download the latest `.dmg` from [Releases](../../releases/latest), open it and drag macDeskpin to Applications.

> First launch: right-click the app → Open (because the build is not notarized yet).

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
