# Limits Widget

**Always-visible macOS desktop widget for AI coding agent subscription limits** — track Claude Code, Codex CLI, and Antigravity 5-hour & weekly quotas at a glance.

[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-000000?logo=apple&logoColor=white)](https://github.com/DmitriyRud/limits-widget/releases)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/DmitriyRud/limits-widget?include_prereleases&label=Release)](https://github.com/DmitriyRud/limits-widget/releases)

<p align="center">
  <img src="docs/images/widget.png" alt="Limits Widget on macOS desktop (Dark Mode)" width="282">
</p>

<!-- Optional: add a light-mode screenshot at docs/images/widget-light.png and uncomment below:
![Limits Widget Light Mode](docs/images/widget-light.png)
-->

---

## Features

- **Multi-agent quota tracking** — Claude Code (`5 hours`, `Weekly`, optional Opus/Sonnet weekly), Codex CLI (`5 hours`, `Weekly`), and Antigravity (`Gemini · 5h`, `Gemini · Weekly`, `Claude & GPT · 5h`, `Claude & GPT · Weekly`, `Gemini 4 Argon · Weekly`).
- **At-a-glance status bars** — remaining percentage with color-coded thresholds: green (> 30% left), orange (10–30%), red (≤ 10%).
- **Live countdowns & tooltips** — updates every minute offline (`in 3h 21m`); hover any row for the exact reset date and time.
- **Stale data protection** — shows data freshness (`as of 14:22`, including date if older than today) and keeps the last known values marked `stale` if a refresh fails.
- **Native desktop widget feel** — borderless macOS-style frosted card sitting at desktop level (above desktop icons, below regular windows), draggable with persistent position.
- **Menu bar controls** — quick **Refresh**, **Settings…** (agent toggles, refresh interval, language), **Launch at login**, and **Quit**.
- **11 UI languages** — English (default), German, Spanish, French, Italian, Norwegian, Icelandic, Finnish, Chinese (Simplified), Japanese, and Russian — switchable live without restarting.
- **Lightweight & zero dependencies** — pure Swift 6 + SwiftUI/AppKit, < 1% idle CPU, < 50 MB RAM, no third-party packages.

## Requirements

- **macOS 14.0 (Sonoma)** or newer.
- **Architecture:** Apple Silicon (`arm64`) — or Universal (`arm64` + `x86_64`) / Intel when built from source.
- Signed-in **Claude Code**, **Codex CLI**, and/or running **Antigravity** on your Mac. The widget reads their local state and never asks for your credentials.

## Installation

### Option 1: Download Pre-Built App (Recommended)

1. Download the latest `LimitsWidget-v1.0.0.zip` from **[GitHub Releases](https://github.com/DmitriyRud/limits-widget/releases)** or **[Gumroad](https://rudakovdev.gumroad.com/l/limits-widget)** (*Pay What You Want — $0+*).
2. Unzip and drag `LimitsWidget.app` into `/Applications/`.
3. Launch `LimitsWidget.app` (see the Gatekeeper note below for the first launch).

### Option 2: Build from Source

Requires Swift 6 (Xcode 16+ or Command Line Tools via `xcode-select --install`):

```bash
git clone https://github.com/DmitriyRud/limits-widget.git
cd limits-widget
scripts/bundle.sh                       # builds release build/LimitsWidget.app
cp -R build/LimitsWidget.app /Applications/
open /Applications/LimitsWidget.app
```

For quick development runs without bundling: `swift run LimitsWidget`.

### First Launch & macOS Gatekeeper

Because Limits Widget is distributed independently without a paid Apple Developer ID notarization certificate, macOS Gatekeeper will warn you on the first launch (*"Apple could not verify…" / "unidentified developer"*). You can open it safely using any of these methods:

1. **Finder right-click:** Right-click (or Control-click) `LimitsWidget.app` in `/Applications/` → click **Open** → confirm **Open**.
2. **System Settings:** Try opening the app once, then go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
3. **Terminal (removes the quarantine flag):**
   ```bash
   xattr -cr /Applications/LimitsWidget.app
   ```

> **Keychain prompt (Claude Code):** macOS may ask once for permission to read `"Claude Code-credentials"` via `/usr/bin/security`. Click **Always Allow** so it won't prompt again.

## Data Sources & Privacy

| Agent | Local Discovery / Credentials (Read-Only) | Limits Source |
|---|---|---|
| **Claude Code** | Keychain `"Claude Code-credentials"` via `/usr/bin/security` (fallback: `~/.claude/.credentials.json`) | `GET https://api.anthropic.com/api/oauth/usage` |
| **Codex CLI** | `~/.codex/auth.json` (`tokens.access_token`, `tokens.account_id`) | `GET https://chatgpt.com/backend-api/wham/usage` (fallback: `~/.codex/sessions` logs) |
| **Antigravity** | `~/.gemini/antigravity/daemon/hub_*.json` (`httpsPort`, `csrfToken`) | Local loopback RPC `POST https://127.0.0.1:<port>/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary` (fallback: `GetUserStatus`) — **zero internet requests** |

- **Strictly read-only:** never modifies agent files or Keychain items, never refreshes OAuth tokens.
- **No telemetry, no third-party servers:** each provider has its own isolated HTTP client with a strict host allowlist and redirects disabled.
- **No secret logging:** tokens and CSRF secrets are redacted in all string/mirror representations; personal fields (`email`, `name`, `user_id`, `account_id`, `profilePictureUrl`) are not decoded.

For full details on Antigravity quota endpoints and limit pools, see [`antigravity-limits.md`](antigravity-limits.md).

## Support the Project

Limits Widget is free and open-source under the MIT License. If it saves you from hitting rate limits mid-task, you can support ongoing development with a *Pay What You Want* ($0+) download or tip on Gumroad:

👉 **[Support on Gumroad](https://rudakovdev.gumroad.com/l/limits-widget)**

## Development

```bash
swift build                             # debug build
scripts/test.sh                         # Swift Testing suite (do not run `swift test` directly with CLT)
swift format -i -r Sources Tests        # format Swift code
```

- `Sources/LimitsCore` — pure Swift models, providers, parsers, formatters, and localization (no AppKit/SwiftUI).
- `Sources/LimitsWidget` — macOS AppKit/SwiftUI desktop panel, menu bar, and Settings UI.
- See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/adr/`](docs/adr/) for architecture notes and contribution guidelines.

## License & Credits

Released under the [MIT License](LICENSE).

Agent logos are from [Simple Icons](https://simpleicons.org) (CC0-1.0). Claude, OpenAI, and Google Antigravity trademarks belong to their respective owners. This project is not affiliated with Anthropic, OpenAI, or Google.
