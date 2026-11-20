# Contributing to Limits Widget

Thanks for your interest in contributing! Bug reports, translations, new AI agent providers, and pull requests are all welcome.

## Development Setup

- **macOS 14+** with **Swift 6** (Xcode 16+ or Command Line Tools)
- Zero external SPM dependencies — everything builds with standard SwiftPM:

```bash
swift build                      # debug build
scripts/test.sh                  # run unit tests (Swift Testing)
scripts/bundle.sh                # build release build/LimitsWidget.app
swift format -i -r Sources Tests # format code
```

> Use `scripts/test.sh` instead of `swift test` directly when building with Command Line Tools only.

## Architecture Overview

- `Sources/LimitsCore/` — platform-independent Swift library (models, providers, parsers, formatters, `L10n`). Keep it free of AppKit/SwiftUI so everything stays unit-testable.
- `Sources/LimitsWidget/` — macOS desktop panel (`NSPanel`), menu bar, and Settings UI.
- `Tests/LimitsCoreTests/` — Swift Testing suite with anonymized JSON/JSONL fixtures in `Fixtures/`.

### Adding a New AI Agent Provider

1. Implement `LimitsProvider` in `Sources/LimitsCore/Providers/<Agent>/`.
2. Keep credential types read-only, non-`Encodable`, and redacted in `description`, `debugDescription`, and `customMirror`.
3. Use a dedicated `URLSessionHTTPClient` with a strict host allowlist for that provider (no redirects) — or prefer a local loopback/file source when available.
4. Add unit tests using **anonymized** fixtures in `Tests/LimitsCoreTests/Fixtures/` (replace any email, user/account ID, UUID, or token with `"REDACTED"`).
5. Register the provider in `AppModel.swift` and add a toggle in `SettingsWindow.swift`.

## Security Rules (Non-Negotiable)

- Never log, print, persist, or commit real API keys, OAuth tokens, JWTs, or personal user data.
- Never modify agent credential files or Keychain items, and never perform OAuth token refreshes.
- Keep `swift build -c release` warning-free under Swift 6 strict concurrency.

## Pull Request Checklist

- [ ] `scripts/test.sh` passes with all tests green.
- [ ] `swift build -c release` compiles with zero warnings.
- [ ] No real tokens, credentials, or personal data in code or test fixtures.
- [ ] New user-facing strings are added to `L10n.swift` across all supported languages.
