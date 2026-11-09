---
spec: 001-limits-widget-mvp
status: approved         # draft | approved | done — после approved хук spec-gate разрешает правки в Sources/
---

# Задачи: MVP виджета лимитов

Формат: `- [ ] T001 [P] Описание — файлы — (FR-xxx)`. `[P]` — параллелится.

## Фаза 1: Подготовка
- [x] T001 Каркас SwiftPM: `LimitsCore`, `LimitsWidget`, `LimitsCoreTests` — `Package.swift` — (III.2)
- [x] T002 Базовые модели `UsageWindow`, `ProviderSnapshot`, протокол `LimitsProvider` — `Sources/LimitsCore/` — (IV.1)
- [x] T003 `ResetFormatter` + тесты — `Sources/LimitsCore/Formatting/` — (FR-005)

## Фаза 2: Тесты (должны падать до реализации)
- [x] T010 [P] Фикстура и тесты `ClaudeUsageResponse` (полный ответ, null-окна, неизвестные поля) — (FR-002)
- [x] T011 [P] Фикстура JSONL и тесты `CodexSessionLogParser` (последнее событие, `timestamp` → `fetchedAt`, битые строки, нет rate_limits) — (FR-004, FR-008)
- [x] T012 [P] Тесты `UsageLevel` порогов 70/90 — (FR-007)
- [x] T013 [P] Тесты `LimitsStore`: один провайдер бросает ошибку, другие отдают данные — (NFR-003)
- [x] T014 [P] Тест: `ClaudeCredentials.description` не содержит токен — (NFR-001)

## Фаза 3: Ядро
- [x] T020 `CredentialSource`: Keychain через `/usr/bin/security`, файловый фоллбэк — (FR-001, FR-003)
- [x] T021 `HTTPClient` с allowlist хостов — (NFR-001, II.3)
- [x] T022 `ClaudeCodeProvider` — (FR-001, FR-002)
- [x] T023 `CodexProvider` (только локальные логи, без сети — Q-2) — (FR-003, FR-004, FR-008)
- [x] T024 `UsageLevel` — (FR-007)
- [x] T025 `LimitsStore` с двумя таймерами — (FR-006, FR-008, FR-012)

## Фаза 4: UI и интеграция
- [x] T030 `DesktopPanel`: уровень рабочего стола, перетаскивание, сохранение позиции — (FR-009)
- [x] T031 `WidgetView` / `WindowRow`: прогресс, %, обратный отсчёт, tooltip — (FR-005, FR-007, FR-008)
- [x] T032 `MenuBarExtra`: Обновить / Настройки / Автозапуск / Выход — (FR-010)
- [x] T033 `SMAppService` автозапуск — (FR-011)
- [x] T034 Настройки: интервал обновления, вкл/выкл провайдеров — (FR-006, FR-013)
- [x] T035 Скрипт сборки `.app`-бандла (`scripts/bundle.sh`, Info.plist с `LSUIElement`) — (FR-011)
- [x] T036 Показ оставшегося процента: `UsageWindow.remainingPercent(now:)` + тесты, `WindowRow` и прогресс-бар показывают остаток — (FR-005, FR-007)
- [x] T038 Логотип агента: `LimitsProvider.logoSVG` (+ цвет) в LimitsCore, `LimitsStore.branding(for:)`, иконка перед названием + тесты — (FR-005, IV.2)
- [x] T039 Оформление как у системного виджета (скругление, подложка, обводка), шкала остатка 10 pt — (FR-005, FR-009)
- [x] T037 Время актуальности данных с датой, если не сегодня: `ResetFormatter.dataAge(_:now:)` + тесты — (FR-008)

## Фаза 6: Codex по сети (пересмотр Q-2, 2026-11-09)
- [x] T050 Проверка `wham/usage` и обезличенная фикстура `codex_usage.json` — research.md R-2 — (FR-004)
- [x] T051 [P] Тесты `CodexUsageResponse`: полный ответ, null-окна, неизвестные поля, битый JSON — (FR-004)
- [x] T052 [P] Тесты `CodexCredentials`: декодирование `tokens`, нет токенов, `description`/`dump` без токена — (FR-003, NFR-001)
- [x] T053 [P] Тесты `CodexProvider`: сеть ок, 401 + логи, 401 без логов, ошибка сети + логи, хост/заголовки — (FR-004, FR-008, NFR-003)
- [x] T054 `CodexCredentials` + `CodexCredentialSource` (файл учётки Codex, только чтение) — (FR-003, NFR-001, NFR-006)
- [x] T055 `CodexUsageResponse` — (FR-004)
- [x] T056 `CodexProvider`: сеть + фоллбэк на журналы; allowlist на провайдера в `LimitsWidget` — (FR-004, FR-008, II.3)
- [x] T057 Ревью безопасности фазы 6 (агент `security-reviewer`) — (NFR-001, NFR-006)

## Фаза 5: Полировка и приёмка
- [ ] T040 Ручная приёмка US-1…US-5
- [ ] T041 Замер NFR-002 (CPU/RAM 10 мин)
- [ ] T042 Ревью безопасности (агент `security-reviewer`) — (NFR-001, NFR-006)
