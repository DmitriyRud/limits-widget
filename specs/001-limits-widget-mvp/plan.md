---
spec: 001-limits-widget-mvp
status: approved         # draft | approved | done
---

# План реализации: MVP виджета лимитов

## Технический подход
Swift Package с двумя таргетами:
- **`LimitsCore`** (library) — модели, провайдеры, парсеры, форматирование. Без AppKit/SwiftUI → тестируется `swift test`.
- **`LimitsWidget`** (executable) — AppKit/SwiftUI-оболочка: desktop-панель, menu bar, настройки (ADR-0001).

Поток данных:
```
Timer(300s) ─▶ LimitsStore (@MainActor, @Observable)
                 └─ async let по каждому LimitsProvider ─▶ ProviderSnapshot
                                                          (status + [UsageWindow])
Timer(60s)  ─▶ пересчёт «через X ч Y мин» из resetsAt (без сети)
```

## Компоненты и файлы
| Компонент | Путь | Требования |
|-----------|------|------------|
| `UsageWindow`, `ProviderSnapshot`, `ProviderStatus` | `Sources/LimitsCore/Models/` | FR-005, FR-008, FR-012 |
| `LimitsProvider` протокол | `Sources/LimitsCore/Providers/LimitsProvider.swift` | IV.1 |
| `CredentialSource` (Keychain/файл, абстракция) | `Sources/LimitsCore/Providers/CredentialSource.swift` | FR-001, FR-003, NFR-001 |
| `HTTPClient` протокол + URLSession-реализация | `Sources/LimitsCore/Providers/HTTPClient.swift` | V.3 |
| `ClaudeCodeProvider` + `ClaudeUsageResponse` | `Sources/LimitsCore/Providers/Claude/` | FR-001, FR-002 |
| `CodexProvider` + `CodexSessionLogParser` (локальные журналы, `fetchedAt` = `timestamp` события) | `Sources/LimitsCore/Providers/Codex/` | FR-003, FR-004, FR-008 |
| `CodexCredentials` + `CodexCredentialSource` (`~/.codex/auth.json`: только `tokens.access_token`, `tokens.account_id`; redacted description) | `Sources/LimitsCore/Providers/Codex/` | FR-003, NFR-001 |
| `CodexUsageResponse` (декодер `wham/usage`) | `Sources/LimitsCore/Providers/Codex/` | FR-004 |
| `ResetFormatter`, `UsageLevel` | `Sources/LimitsCore/Formatting/` | FR-005, FR-007 |
| `LimitsStore` (агрегатор) | `Sources/LimitsCore/LimitsStore.swift` | FR-006, NFR-003 |
| `DesktopPanel` (NSPanel) | `Sources/LimitsWidget/DesktopPanel.swift` | FR-009 |
| `WidgetView`, `WindowRow` | `Sources/LimitsWidget/Views/` | FR-005, FR-007, FR-008 |
| `MenuBar`, `Settings`, `LoginItem` | `Sources/LimitsWidget/` | FR-010, FR-011, FR-013 |

## Модель данных
```swift
struct UsageWindow { kind: WindowKind (.session5h, .weekly, .weeklyModel(String), .custom(minutes))
                     usedPercent: Double (0...100), resetsAt: Date? }
enum ProviderStatus { .ok, .notAuthenticated, .tokenExpired, .noData, .error(String) }
struct ProviderSnapshot { providerID, displayName, status, windows: [UsageWindow], fetchedAt: Date }
```
Инвариант: `usedPercent` клампится в 0...100; если `resetsAt < now` → эффективный процент 0 (FR-012).

## Внешние интерфейсы
См. `research.md` R-1, R-2. Фикстуры: `Tests/LimitsCoreTests/Fixtures/`.
Keychain (R-3): MVP читает через `/usr/bin/security find-generic-password -s ... -w` в `Process`,
stdout сразу декодируется в `ClaudeCredentials` и не сохраняется. `ClaudeCredentials.description`
переопределён → `"<redacted>"`.

## Стратегия тестирования
- Unit: парсеры обоих провайдеров на фикстурах (включая `null`-окна, неизвестные поля, битые строки JSONL),
  `ResetFormatter` (границы: 0 мин, < 1 ч, > 1 сут, прошедшее время), `UsageLevel` пороги,
  `LimitsStore` с фейковыми провайдерами (один падает — другие работают).
- Ручная приёмка: сценарии US-1…US-5 из spec.md, замер NFR-002.

## Риски
| Риск | Вероятн. | Митигация |
|------|----------|-----------|
| Эндпоинт Claude `oauth/usage` изменится | средняя | толерантный декодер, статус «формат изменился» |
| Codex-лог устарел (Codex давно не запускали) | высокая | основной источник — сеть (фаза 6); в фоллбэке — `fetchedAt` с датой + FR-012 |
| Недокументированный `wham/usage` изменится | средняя | толерантный декодер, фоллбэк на локальные журналы |
| Диалог Keychain при каждой пересборке | высокая | чтение через `/usr/bin/security` (R-3) |

## Проверка конституции
I ✅ · II ✅ (только чтение, redacted description, хост-allowlist в `HTTPClient`) · III ✅ (без зависимостей, ADR-0001) · IV ✅ · V ✅

## Codex по сети (фаза 6, пересмотр Q-2)
Логика `CodexProvider.fetchSnapshot()`:
```
нет auth.json                             → .notAuthenticated
нет tokens.access_token (API-ключ)     → локальные журналы (как раньше)
GET chatgpt.com/backend-api/wham/usage → 200 + валидный JSON → .ok, windows, fetchedAt = now
                                       → 401/403, другой код, сеть, формат → локальные журналы:
                                            есть сэмпл → .ok с fetchedAt лога (FR-008 покажет дату)
                                            нет сэмпла → 401/403: .tokenExpired; иначе .error(сообщение)
```
- Заголовки: `Authorization: Bearer`, `ChatGPT-Account-Id` (если есть), `Accept: application/json`, `User-Agent: LimitsWidget/<версия>`.
- **Allowlist хостов — на провайдера** (конституция II.3): у `ClaudeCodeProvider` свой `URLSessionHTTPClient(["api.anthropic.com"])`,
  у `CodexProvider` — свой `URLSessionHTTPClient(["chatgpt.com"])`; токен одного провайдера не может уйти на хост другого.
- `CodexUsageResponse`: декодирует только `rate_limit.primary_window/secondary_window` (`used_percent`, `limit_window_seconds`,
  `reset_at`); `user_id`/`account_id`/`email` не декодируются. `null`-окна пропускаются.
- `CodexCredentials`: как `ClaudeCredentials` — без `Hashable`/`Encodable`, токен `internal`, `description`/`Mirror` скрыты.
- Тесты: фикстура `codex_usage.json` (+ null-окна, неизвестные поля, битый JSON); провайдер — фейковые HTTP и источник
  учётки + временный каталог логов: успех сети, 401 с логами и без, ошибка сети с логами, проверка хоста и заголовков.

## Отклонения (заполняется при реализации)
- **D-1 (T030, ADR-0001) — принято владельцем 2026-11-09, ADR-0001 обновлён.** Уровень панели `CGWindowLevelForKey(.desktopIconWindow) + 1`
  вместо ровно `.desktopIconWindow`. Причина: на уровне окна значков Finder порядок относительно значков не гарантирован
  и перетаскивание мышью (FR-009) может не работать; +1 держит виджет над значками, но под обычными окнами.
  Проверено вручную: перетаскивание и сохранение позиции работают.
- D-2 (T022, информативно): добавлен `Models/ProviderStatus+Messages.swift` — русские тексты ошибок провайдеров в одном месте.
- D-3 (T021, по итогам security-review): `URLSessionHTTPClient` запрещает HTTP-редиректы (`NoRedirectDelegate`), чтобы
  allowlist хостов нельзя было обойти; `ClaudeCredentials` без `Hashable`, `accessToken` — `internal`; таймаут 60 с у `security`.
- D-4 (T057, по итогам security-review фазы 6): фабрики `URLSessionHTTPClient.forClaude()/forCodex()` в LimitsCore с тестом
  привязки «провайдер → хост»; клиенты создаются один раз на приложение (без накопления `URLSession` при пересборке стора).
