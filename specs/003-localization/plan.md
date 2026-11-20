---
spec: 003-localization
status: done         # draft | approved | done
---

# Implementation Plan: Multi-Language Localization & English Documentation

## Technical Approach
Because Limits Widget runs both via `swift run LimitsWidget` (SPM executable without `.lproj` resources) and as `build/LimitsWidget.app` (assembled by `scripts/bundle.sh`), using a pure-Swift type-safe localization catalog (`AppLanguage` + `L10n` in `LimitsCore`) guarantees:
1. Instant live language switching in SwiftUI without restarting the app.
2. Identical behavior in `swift run`, `scripts/test.sh`, and `build/LimitsWidget.app`.
3. Compile-time exhaustiveness across all 11 languages (`switch language` with no `default:` fallback).

To ensure live switching updates Antigravity group labels and provider error messages without re-fetching:
- Add structured `WindowKind.group(String, WindowPeriod)` (`.fiveHour`, `.weekly`, `.other(String)`) so `ResetFormatter.title(for:language:)` formats `"Gemini · 5h"` / `"Gemini · 5 ч"` / `"Gemini · 5 Std."` dynamically in the active language.
- Keep `ResetFormatter` methods accepting `language: AppLanguage = .en` (defaulting to `.en`).
- Localize `ProviderStatus` error messages via `L10n.providerError(for:language:)` (mapping canonical error keys / existing messages cleanly without breaking `ProviderStatus.error(String)`).

## Components and Files
| Component | Path | Covers |
|-----------|------|--------|
| `AppLanguage` enum (11 languages, `en` default, native display names, `Locale`) | `Sources/LimitsCore/Formatting/AppLanguage.swift` | FR-001, FR-003 |
| `L10n` translation catalog (all 11 languages, exhaustive `switch`) | `Sources/LimitsCore/Formatting/L10n.swift` | FR-001, FR-002 |
| `WindowKind.group(String, WindowPeriod)` | `Sources/LimitsCore/Models/UsageWindow.swift` | FR-002, FR-004 |
| `AntigravityQuotaSummaryResponse` (emit `.group(name, period)`) | `Sources/LimitsCore/Providers/Antigravity/AntigravityQuotaSummaryResponse.swift` | FR-002, FR-004 |
| `ResetFormatter` (accept `language: AppLanguage = .en`) | `Sources/LimitsCore/Formatting/ResetFormatter.swift` | FR-002, FR-004 |
| `ProviderStatus+Messages` (language-aware lookup) | `Sources/LimitsCore/Models/ProviderStatus+Messages.swift` | FR-002, FR-004 |
| `AppModel.language` (`UserDefaults` key `appLanguage`, default `.en`) | `Sources/LimitsWidget/AppModel.swift` | FR-003, FR-004 |
| `SettingsWindow` (Language `Picker`, live localized title & labels) | `Sources/LimitsWidget/SettingsWindow.swift` | FR-003, FR-004 |
| `WidgetView`, `WindowRow`, `StatusText`, `MenuBarContent` | `Sources/LimitsWidget/` | FR-002, FR-004 |
| English documentation | `README.md`, `antigravity-limits.md`, `docs/adr/0001-desktop-window-instead-of-widgetkit.md` | FR-005 |
| Unit tests | `Tests/LimitsCoreTests/LocalizationTests.swift` + updated formatter/provider tests | NFR-003 |

## Testing Strategy
- Unit tests (`LocalizationTests.swift`):
  - Verify `AppLanguage.allCases.count == 11` and `AppLanguage.default == .en`.
  - For every `AppLanguage`, verify every string key and formatter output is non-empty and distinct where expected.
  - Verify `ResetFormatter.relative`, `dataAge`, and `title(for:)` in English (default), Russian, German, Japanese, Chinese, etc.
  - Update existing `ResetFormatterTests`, `RemainingAndDataAgeTests`, `AntigravityQuotaSummaryResponseTests`, `AntigravityProviderTests` for default `.en` (and explicit `.ru` where testing Russian formatting).
- Build & bundle verification: `scripts/test.sh` and `scripts/bundle.sh` with zero warnings.

## Constitution Compliance
I ✅ · II ✅ · III ✅ · IV ✅ · V ✅

## Deviations
- *(none yet)*
