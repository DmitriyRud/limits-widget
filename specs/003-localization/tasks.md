---
spec: 003-localization
status: done         # draft | approved | done — approved by owner
---

# Tasks: Multi-Language Localization & English Documentation

Format: `- [ ] T001 [P] Description — files — (FR-xxx)`

## Phase 1: Tests
- [x] T001 [P] Add `LocalizationTests` covering all 11 languages, default `.en`, all `L10n` strings, `ResetFormatter` localized outputs, and `WindowKind.group` — `Tests/LimitsCoreTests/LocalizationTests.swift` — (FR-001, FR-002, NFR-003)
- [x] T002 [P] Update existing formatter/Antigravity tests for English default and localized titles — `Tests/LimitsCoreTests/ResetFormatterTests.swift`, `Tests/LimitsCoreTests/RemainingAndDataAgeTests.swift`, `Tests/LimitsCoreTests/AntigravityQuotaSummaryResponseTests.swift`, `Tests/LimitsCoreTests/AntigravityProviderTests.swift` — (FR-001, FR-002)

## Phase 2: Core (`LimitsCore`)
- [x] T003 [P] Add `AppLanguage` enum (11 languages, default `.en`, native names, `Locale`) — `Sources/LimitsCore/Formatting/AppLanguage.swift` — (FR-001, FR-003)
- [x] T004 [P] Add `L10n` exhaustive translation catalog for all 11 languages — `Sources/LimitsCore/Formatting/L10n.swift` — (FR-001, FR-002)
- [x] T005 Add `WindowPeriod` and `WindowKind.group(String, WindowPeriod)`, update `AntigravityQuotaSummaryResponse`, `ResetFormatter`, and `ProviderStatus+Messages` — `Sources/LimitsCore/Models/UsageWindow.swift`, `Sources/LimitsCore/Providers/Antigravity/AntigravityQuotaSummaryResponse.swift`, `Sources/LimitsCore/Formatting/ResetFormatter.swift`, `Sources/LimitsCore/Models/ProviderStatus+Messages.swift` — (FR-002, FR-004)

## Phase 3: UI (`LimitsWidget`)
- [x] T006 Add `AppModel.language` persisted in `UserDefaults` (`appLanguage`, default `.en`) — `Sources/LimitsWidget/AppModel.swift` — (FR-003, FR-004)
- [x] T007 Add Language `Picker` and localized labels/title in `SettingsWindow` — `Sources/LimitsWidget/SettingsWindow.swift` — (FR-003, FR-004)
- [x] T008 Localize `WidgetView`, `WindowRow`, `StatusText`, and `MenuBarContent` — `Sources/LimitsWidget/Views/WidgetView.swift`, `Sources/LimitsWidget/Views/WindowRow.swift`, `Sources/LimitsWidget/Views/StatusText.swift`, `Sources/LimitsWidget/MenuBarContent.swift` — (FR-002, FR-004)

## Phase 4: Documentation
- [x] T009 [P] Translate `README.md`, `antigravity-limits.md`, and `docs/adr/0001-desktop-window-instead-of-widgetkit.md` to English — `README.md`, `antigravity-limits.md`, `docs/adr/0001-desktop-window-instead-of-widgetkit.md` — (FR-005)

## Phase 5: Verification
- [x] T010 Run `scripts/test.sh` and `scripts/bundle.sh` (zero warnings, Swift 6 strict concurrency) — (NFR-001…NFR-004)
