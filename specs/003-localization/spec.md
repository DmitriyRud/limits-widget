---
id: 003-localization
status: done         # draft | approved | done — approved by owner
owner: Dmitriy Rudakov
created: 2026-11-20
---

# Specification: Multi-Language Localization & English Documentation

## Context and Problem
Limits Widget currently has hardcoded Russian UI strings and Russian project documentation. To make the app usable internationally, the widget UI and core formatters need full localization into 11 languages (English as default, plus German, Spanish, French, Italian, Norwegian, Icelandic, Finnish, Chinese, Japanese, and Russian) with a live language picker in Settings, and the project documentation should be translated into English.

## User Stories
- **US-1** As a new user, when I launch Limits Widget for the first time, the interface is in English by default.
  - Acceptance: Given no saved language preference, When I open the widget, menu bar, and Settings, Then all labels, countdowns, dates, tooltips, and statuses appear in English.
- **US-2** As a user, I can switch the widget language in Settings to English, German, Spanish, French, Italian, Norwegian, Icelandic, Finnish, Chinese (Simplified), Japanese, or Russian, and the change takes effect immediately and persists across restarts.
  - Acceptance: Given the widget is running, When I select a new language in Settings, Then the widget panel, menu bar items, Settings window title/labels, countdowns, and window titles update immediately without restarting and remain selected after relaunch.
- **US-3** As a developer reading the repository on GitHub, I can read the documentation (`README.md`, `antigravity-limits.md`, `docs/adr/*`) in English.

## Functional Requirements
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Support 11 languages in `LimitsCore` and `LimitsWidget`: English (`en`, default), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Norwegian (`nb`), Icelandic (`is`), Finnish (`fi`), Chinese Simplified (`zh-Hans`), Japanese (`ja`), and Russian (`ru`) | MUST |
| FR-002 | Localize all user-facing strings: window titles (`5h`, `Weekly`, model/group pools, overall, custom), remaining percent label, relative countdown (`in Xd Yh` / `reset`), data age (`as of …`) and date formatting, tooltips (`Resets: …`), provider statuses and error messages, menu bar actions, and Settings window | MUST |
| FR-003 | Add a Language picker in the Settings window displaying each language in its native name; persist selection in `UserDefaults` (`appLanguage`) with English (`en`) as default | MUST |
| FR-004 | Changing the language updates all visible UI (desktop widget, menu bar, Settings window title and labels, Antigravity group labels, and error messages) immediately without restarting or re-fetching network data | MUST |
| FR-005 | Translate user-facing project documentation (`README.md`, `antigravity-limits.md`, `docs/adr/0001-desktop-window-instead-of-widgetkit.md`) into English | MUST |

## Non-Functional Requirements
| ID | Requirement | Verification |
|----|-------------|--------------|
| NFR-001 | Zero external SPM dependencies; pure Swift 6 `Sendable` localization catalog in `LimitsCore` | code review + `Package.swift` |
| NFR-002 | Clean `swift build -c release` with zero warnings under Swift 6 strict concurrency | `scripts/bundle.sh` |
| NFR-003 | Unit tests verify all 11 languages have complete non-empty translations for every string key, formatter output, and window title | `scripts/test.sh` |
| NFR-004 | No security regressions (tokens/credentials handling untouched) | code review + existing tests |

## Non-Goals
- Right-to-left (RTL) layout adaptations (none of the 11 languages are RTL).
- Automatic OS locale detection override (explicit default is English per owner request; user switches in Settings).
- Translating historical `specs/001-*` and `specs/002-*` archives.

## Open Questions
*(none — all requirements specified by owner on 2026-11-20)*

## Constitution Compliance
- [x] I. SDD — tracked as feature `003-localization`
- [x] II. Security — no credential or network changes
- [x] III. Native & Simple — pure Swift 6, zero dependencies, no `.lproj`/Xcode bundle complexity required for `swift run`
- [x] IV. Extensibility — `AppLanguage` and `L10n` in `LimitsCore`, structured `WindowKind` keeps UI provider-agnostic
- [x] V. Testability — full unit test coverage across all 11 languages
