<div align="center">

# 🔭 AWV (A Web Viewer)

**Ultra-Lightweight, Lightning-Fast Native WebKit Viewer for macOS**

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)
![WebKit](https://img.shields.io/badge/WebKit-23BCFA?style=for-the-badge&logo=safari&logoColor=white)

*A privacy-focused, borderless, zero-distraction web viewer built natively with pure Swift and WebKit. Not your standard browser.*

</div>

---

## 🚀 Features

- **Blazing Fast**: Native implementation utilizing `WKWebView` under the hood. No Chromium bloat, minimal RAM usage.
- **Aggressive Ad-Blocking**: Built-in surgical content blockers utilizing compiled rule lists alongside custom localized DOM observers.
- **SPA-Aware Architecture**: Advanced context-aware proxy. Blocks intensive autoplays on Home Pages (like Twitch) but seamlessly permits content on inner routes. 
- **Distraction-Free Mode**: Immersive mode right out of the box with `HiddenTitleBarWindowStyle`. No clutter.
- **Keyboard & Native Driven**: Deep shortcuts (`Cmd+`/`Cmd-`), Middle-click isolation for window spawning, and fluid navigation.

## 🕹 Quick Start

No bloated Xcode projects here. Build the entire application organically via CLI tools:

```zsh
# 1. Clone the project
git clone https://github.com/your-username/awv-mlx.git
cd awv-mlx

# 2. Compile into an application MacOS binary
swiftc -parse-as-library AWV.swift -o AWV.app/Contents/MacOS/AWV

# 3. Ad-Hoc sign the application locally
codesign --force --deep --sign - AWV.app

# 4. Deploy to Applications
cp -a AWV.app /Applications/
```

## 🏗 Architecture

Crafted entirely in high-performance Swift using Apple's Declarative UI. We eschew XIB files and Xcode bloat in favor of a zero-calorie compilation workflow.

- **Frontend**: SwiftUI (`WindowGroup`, `LazyVGrid`, `ZStack`) seamlessly integrated with AppKit features.
- **Core Engine**: Apple's `WebKit` (`WKWebView`, `WKNavigationDelegate`) fully decoupled via SwiftUI `NSViewRepresentable`.
- **Security & Blocking**: Pre-compiled `ContentRuleList` blocking, fortified with surgically-injected JavaScript payload observers.

## 🤝 Contributing
Feel free to open issues or PRs! Let's keep it beautifully minimalist.

---
<div align="center">
<i>Crafted with ✨ for the macOS Ecosystem</i>
</div>
