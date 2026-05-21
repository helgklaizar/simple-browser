# Обзор проекта AWV (A Web Viewer)

## Описание
Ультра-лёгкий нативный WebKit-браузер для macOS без Chromium-блоата, ориентированный на приватность.

## Стек технологий
Swift, SwiftUI, WebKit (WKWebView), macOS native

## Ключевые файлы и директории
- `adblock_rules.json` — правила блокировки рекламы
- `SPA-aware proxy` — прокси для SPA
- `distraction-free mode` — режим скрытого заголовка
- `Custom User Agent` — подмена User-Agent для обхода анти-бот систем

## Важные особенности / Контекст
Компилируется напрямую без использования Xcode (через swiftc CLI), затем подписывается (codesign) и копируется в /Applications/. Должен обязательно находиться в /Applications, иначе macOS применит App Translocation. Поддерживает Middle-click для открытия ссылки в новом окне.
