<div align="center">

# 🪐 Mini Orion (macOS)

**Ultra-Lightweight, Lightning-Fast Native WebKit Browser for macOS**

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)
![WebKit](https://img.shields.io/badge/WebKit-23BCFA?style=for-the-badge&logo=safari&logoColor=white)

*A privacy-focused, borderless, zero-distraction browsing experience built with pure Swift and WebKit.*

</div>

---

## 🚀 Features

- **Blazing Fast**: Native implementation utilizing `WKWebView` under the hood. No Chromium bloat, minimal RAM usage, no Electron overhead.
- **Aggressive Ad-Blocking**: Built-in surgical content blockers utilizing compiled rule lists (re-routing and blocking invasive ads directly at the network layer) alongside custom DOM injection for heavy-ad streaming sites.
- **Distraction-Free Mode**: Immersive mode right out of the box with `HiddenTitleBarWindowStyle`. No clutter.
- **Keyboard-Driven**: Deep shortcuts for blazing fast zooming (`Cmd+`/`Cmd-`), reloading (`Cmd+R`), and streamlined navigation.
- **SPA Resilient**: Prevents background pop-ups from hijacking the main view routing on SPAs like Twitch.

## 🕹 Quick Start

No bloated Xcode projects here. Build the entire application organically via CLI tools:

```zsh
# 1. Clone the project
git clone https://github.com/your-username/mini-orion.git
cd mini-orion

# 2. Compile into an application MacOS binary
swiftc -parse-as-library MiniOrion.swift -o MiniOrion.app/Contents/MacOS/MiniOrion

# 3. Ad-Hoc sign the application locally
codesign --force --deep --sign - MiniOrion.app

# 4. Deploy to Applications
cp -a MiniOrion.app /Applications/
```

## 🏗 Architecture

Crafted entirely in high-performance Swift using Apple's Declarative UI. We eschew XIB files and Xcode bloat in favor of a zero-calorie compilation workflow.

- **Frontend**: SwiftUI (`WindowGroup`, `TextField`, `ZStack`) seamlessly integrated with AppKit features.
- **Core Engine**: Apple's `WebKit` (`WKWebView`, `WKNavigationDelegate`) fully decoupled via SwiftUI `NSViewRepresentable`.
- **Security & Blocking**: Pre-compiled `ContentRuleList` blocking, fortified with localized JavaScript payload observers.

## 🤝 Contributing
Feel free to open issues or PRs! Let's keep it beautifully minimalist.

---
<div align="center">
<i>Crafted with ✨ for the macOS Ecosystem</i>
</div>
