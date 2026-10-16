# مصاريفي · Masarify

Native **SwiftUI iOS** app for personal expense tracking. Arabic-first (RTL), SwiftData persistence, voice entry, and receipt capture with Vision OCR (with honest mock fallback).

## Features (MVP)

1. **Expenses by category** — create, list, edit, delete (أكل، مواصلات، فواتير، ترفيه، تسوق، صحة، أخرى). Stored with **SwiftData**.
2. **Voice entry** — Speech framework (`ar-EG` / `en-US`) + bilingual amount/category/note parser. If speech is unavailable, use **تجربة تجريبية**.
3. **Receipt / invoice** — camera or photo library → Vision OCR (or heuristic/mock) → review → save.
4. **Daily report** — today total, category breakdown, recent entries on Home and Report tabs.
5. **Native iOS UI** — `TabView`, large titles, mic + camera primary actions, Masarify brand hero.

## Requirements

- macOS with **Xcode 15+** (tested with Xcode 26)
- iOS 17+ Simulator or device
- For voice on device: microphone + Speech permissions
- For receipts: camera / photos permissions

## Open & run

```bash
open ~/Desktop/Masarify/Masarify.xcodeproj
```

Or from Terminal:

```bash
cd ~/Desktop/Masarify
xcodebuild -scheme Masarify -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
# Then Run (⌘R) from Xcode, or install the built .app with simctl
```

1. Open `Masarify.xcodeproj` in Xcode.
2. Select an iPhone Simulator (e.g. iPhone 17 Pro) or a signed device.
3. Press **Run** (⌘R).
4. If prompted, allow Microphone / Speech / Camera / Photos.

Absolute path on this Mac: `/Users/Nasser/Desktop/Masarify`

## Project layout

```
Masarify/
  Masarify.xcodeproj
  Masarify/
    MasarifyApp.swift
    Models/          # Expense, categories
    Services/        # Speech, voice parser, Vision OCR
    Theme/           # Brand colors & formatting
    Views/           # Home, expenses, voice, receipt, report
    Assets.xcassets
    Info.plist
  README.md
```

## Limitations

- App icon is a placeholder (AccentColor only); add a 1024×1024 marketing icon before App Store.
- Simulator camera is limited — use the photo library or the demo/mock OCR path.
- Speech quality depends on device/Simulator mic and network (Apple Speech).
- Vision OCR works best on clear receipts; otherwise the app falls back to heuristic/mock extract for review → save.
- No Face ID, cloud sync, budgets, or shared expenses (Phase 2).
- Not packaged for App Store submission in this slice.

## Stack

SwiftUI · SwiftData · Speech · Vision · PhotosUI
