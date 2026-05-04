# 🧭 AWV (A Web Viewer) — Project Memory (Simple Browser)

## 📌 Essence & Stack
- **What is it:** An ultra-lightweight, native macOS web viewer focused on zero-distraction browsing and aggressive ad-blocking.
- **Tech Stack:** Pure Swift, SwiftUI, AppKit, WebKit. No Xcode bloat, built via CLI (`swiftc`).
- **Core Goal:** Fast, privacy-first, borderless browsing.

## 🛑 CRITICAL RESTRICTIONS (Red Flags)

## 🚀 Deployment & Environment
- **Build command:** `./build.sh` (compiles `Sources/**/*.swift` and deploys to `/Applications/AWV.app`)

## 🧭 Restrictions (Guidelines)
# CRITICAL RESTRICTIONS (Red Flags)
- **Local Native First:** Must use `WKWebView` and pure Swift. No Chromium, no Electron/Tauri bloat.
- **Simplicity:** Keep the UI minimal (HiddenTitleBarWindowStyle) and performance high. Do not over-engineer features.
- **Antigravity Rule:** Keep `GEMINI.md` updated with architectural decisions as the project evolves.
