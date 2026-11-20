---
spec: 002-antigravity-provider
status: done         # draft | approved | done — утверждает владелец
---

# Задачи: Поддержка Antigravity в виджете лимитов

Формат: `- [ ] T001 [P] Описание — файлы — (FR-xxx)`
`[P]` — можно выполнять параллельно (не трогает общие файлы с соседними задачами).
Порядок: тесты раньше реализации (TDD), модели раньше сервисов, сервисы раньше UI.

## Фаза 1: Подготовка и фикстура
- [x] T001 Добавить обезличенную фикстуру реального ответа `GetUserStatus` (с пулами Neon/Argon/Claude и пустым `quotaInfo: {}` у `Gemini 4 Carbon`) — `Tests/LimitsCoreTests/Fixtures/antigravity_user_status.json` — (FR-002, FR-006, NFR-005)

## Фаза 2: Тесты (должны падать до реализации)
- [x] T002 [P] Тесты на `WindowKind.overall` и `ResetFormatter.title(for: .overall)` — `Tests/LimitsCoreTests/ResetFormatterTests.swift` — (FR-002, FR-003)
- [x] T003 [P] Тесты парсинга и агрегации минимума квот (`AntigravityUsageResponse`: фикстура, пустой `quotaInfo: {}`, `remainingFraction == nil` с `resetTime`, истёкший `resetTime`, равенство остатков, неизвестные поля, пустой список, битый JSON) — `Tests/LimitsCoreTests/AntigravityUsageResponseTests.swift` — (FR-002, FR-004, FR-006, NFR-005)
- [x] T004 [P] Тесты `AntigravityDaemonDiscovery` и `AntigravityHubInfo` (чтение `hub_*.json`, сортировка по `mtime`, пропуск битых файлов, redacted `description`/`debugDescription`/`Mirror`) — `Tests/LimitsCoreTests/AntigravityDaemonDiscoveryTests.swift` — (FR-001, NFR-001, NFR-002)
- [x] T005 [P] Тесты `AntigravityProvider` (успех первого хаба, фоллбэк на второй хаб, нет хабов → `.noData`, 401/403 → `.notAuthenticated`, битый JSON → `.error`, проверка заголовков) — `Tests/LimitsCoreTests/AntigravityProviderTests.swift` — (FR-001, FR-002, FR-006, NFR-001, NFR-003)
- [x] T006 [P] Тест логотипа Antigravity в `ProviderBrandingTests` — `Tests/LimitsCoreTests/ProviderBrandingTests.swift` — (FR-003)

## Фаза 3: Ядро (`LimitsCore`)
- [x] T007 Добавить `WindowKind.overall` и подпись `"Общий лимит"` — `Sources/LimitsCore/Models/UsageWindow.swift`, `Sources/LimitsCore/Formatting/ResetFormatter.swift` — (FR-002, FR-003)
- [x] T008 [P] Реализовать `AntigravityHubInfo` и `AntigravityDaemonDiscovery` (только чтение `~/.gemini/antigravity/daemon/hub_*.json`) — `Sources/LimitsCore/Providers/Antigravity/AntigravityDaemonDiscovery.swift` — (FR-001, NFR-001, NFR-002)
- [x] T009 [P] Реализовать `AntigravityUsageResponse` и агрегатор минимального остатка — `Sources/LimitsCore/Providers/Antigravity/AntigravityUsageResponse.swift` — (FR-002, FR-004, FR-006)
- [x] T010 [P] Реализовать `AntigravityLocalClient` (loopback `127.0.0.1` без редиректов, самоподписанный TLS только для `127.0.0.1`) — `Sources/LimitsCore/Providers/Antigravity/AntigravityLocalClient.swift` — (FR-001, FR-002, NFR-001)
- [x] T011 [P] Добавить `AntigravityProvider+Branding` (SVG-логотип и цвет) — `Sources/LimitsCore/Providers/Antigravity/AntigravityProvider+Branding.swift` — (FR-003)
- [x] T012 Реализовать `AntigravityProvider` — `Sources/LimitsCore/Providers/Antigravity/AntigravityProvider.swift` — (FR-001…FR-006, NFR-003)

## Фаза 4: UI и интеграция (`LimitsWidget`)
- [x] T013 Подключить `AntigravityProvider` в `AppModel` (флаг `antigravityEnabled` в `UserDefaults`) и добавить `Toggle("Antigravity", ...)` в `SettingsWindow` — `Sources/LimitsWidget/AppModel.swift`, `Sources/LimitsWidget/SettingsWindow.swift` — (FR-003, FR-005)

## Фаза 5: Проверка и приёмка
- [x] T014 Прогнать `scripts/test.sh`, `swift build -c release` (без предупреждений, Swift 6), проверить форматирование и security-инварианты — (NFR-001…NFR-005)
- [x] T015 Собрать `build/LimitsWidget.app` (`scripts/bundle.sh`) и провести ручную приёмку US-1…US-3 — (FR-001…FR-006, NFR-006)
