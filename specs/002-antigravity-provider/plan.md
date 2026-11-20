---
spec: 002-antigravity-provider
status: done         # draft | approved | done
---

# План реализации: Поддержка Antigravity в виджете лимитов

## Технический подход
Провайдер `AntigravityProvider: LimitsProvider` в `Sources/LimitsCore/Providers/Antigravity/`, работающий с локальным `agy --hub` Antigravity 2.0 (без выхода в интернет и без чтения OAuth-токенов — конституция II.4):

```
AntigravityProvider.fetchSnapshot():
  1. AntigravityDaemonDiscovery.discover() читает `~/.gemini/antigravity/daemon/hub_*.json`
     (сортировка по убыванию mtime; поля: `csrfToken`, `httpsPort`, `httpPort`, `pid`).
     - Если файлов нет → `.noData` (Antigravity не запущен).
  2. По списку найденных хабов (начиная с самого свежего):
     - `POST https://127.0.0.1:<httpsPort>/exa.language_server_pb.LanguageServerService/GetUserStatus`
       (если `httpsPort` не задан/0 — `http://127.0.0.1:<httpPort>`)
     - Заголовки: `Content-Type: application/json`, `Connect-Protocol-Version: 1`,
       `X-Codeium-Csrf-Token: <csrfToken>`.
     - Тело: `{"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"}}`.
     - Если конкретный `hub_*.json` устарел (connection refused) → пробуем следующий файл в каталоге.
  3. Ответ 200 → `AntigravityUsageResponse` декодирует только `userStatus.cascadeModelConfigData.clientModelConfigs[].quotaInfo`
     (персональные поля `email`, `name`, `profilePictureUrl` не декодируются).
  4. Агрегация в один общий индикатор (Q-2, FR-002, FR-004, FR-006):
     - Пропускаем модели с пустым `quotaInfo` (`remainingFraction == nil && resetTime == nil`, как `"Gemini 4 Carbon"`).
     - Если `resetTime != nil && resetTime <= now` → `remaining = 1.0`.
     - Иначе если `remainingFraction == nil && resetTime != nil` → `remaining = 0.0` (protobuf v3 zero-omission).
     - Иначе `remaining = clamp(remainingFraction, 0...1)`.
     - Выбираем запись с минимальным `remaining` (при равенстве — с более ранним `resetTime` в будущем).
     - Возвращаем `[UsageWindow(kind: .overall, usedPercent: (1 - remaining) * 100, resetsAt: resetTime)]`.
  5. При ошибке формата → `.error(ProviderErrorMessage.invalidFormat)`; при недоступности всех хабов → `.noData`
     (`LimitsStore` при этом сохраняет предыдущий удачный снимок с пометкой «данные устарели»).
```

## Компоненты и файлы
| Компонент | Путь | Покрывает требования |
|-----------|------|----------------------|
| `WindowKind.overall` + `ResetFormatter.title` | `Sources/LimitsCore/Models/UsageWindow.swift`, `Sources/LimitsCore/Formatting/ResetFormatter.swift` | FR-002, FR-003 |
| `AntigravityHubInfo` + `AntigravityDaemonDiscovery` (только чтение `hub_*.json`, `csrfToken` скрыт в `description`/`Mirror`) | `Sources/LimitsCore/Providers/Antigravity/AntigravityDaemonDiscovery.swift` | FR-001, NFR-001, NFR-002 |
| `AntigravityLocalClient` (протокол + loopback `URLSession` строго на `127.0.0.1`, без редиректов, самоподписанный TLS только для `127.0.0.1`) | `Sources/LimitsCore/Providers/Antigravity/AntigravityLocalClient.swift` | FR-001, FR-002, NFR-001 |
| `AntigravityUsageResponse` (декодер `GetUserStatus` + агрегатор минимума) | `Sources/LimitsCore/Providers/Antigravity/AntigravityUsageResponse.swift` | FR-002, FR-004, FR-006 |
| `AntigravityProvider` | `Sources/LimitsCore/Providers/Antigravity/AntigravityProvider.swift` | FR-001…FR-006, NFR-003 |
| `AntigravityProvider+Branding` (SVG-логотип + цвет) | `Sources/LimitsCore/Providers/Antigravity/AntigravityProvider+Branding.swift` | FR-003 |
| Регистрация провайдера и переключатель в настройках | `Sources/LimitsWidget/AppModel.swift`, `Sources/LimitsWidget/SettingsWindow.swift` | FR-005 |
| Фикстура и unit-тесты | `Tests/LimitsCoreTests/Fixtures/antigravity_user_status.json`, `Tests/LimitsCoreTests/Antigravity*Tests.swift` | NFR-001, NFR-005 |

## Модель данных
```swift
// Расширение WindowKind (не зависит от конкретного провайдера — IV.2)
public enum WindowKind: Hashable, Sendable {
    case session5h
    case weekly
    case weeklyModel(String)
    case overall
    case custom(minutes: Int)
}

// Метаданные локального хаба (csrfToken internal, без Encodable/Hashable, description → "<redacted>")
public struct AntigravityHubInfo: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public let httpsPort: Int?
    public let httpPort: Int?
    public let pid: Int?
    let csrfToken: String
}
```

## Внешние интерфейсы
- Локальные файлы `~/.gemini/antigravity/daemon/hub_*.json` (только чтение, права `0600`).
- Loopback RPC: `POST https://127.0.0.1:<httpsPort>/exa.language_server_pb.LanguageServerService/GetUserStatus`.
- Отдельный `AntigravityLocalClient` принимает самоподписанный TLS-сертификат **исключительно** для хоста `127.0.0.1` и запрещает HTTP-редиректы; `URLSessionHTTPClient` для внешних хостов не ослабляется.

## Стратегия тестирования
- **Unit-тесты (Swift Testing, без сети и реального `~/.gemini`):**
  - `AntigravityUsageResponseTests`: парсинг реальной обезличенной фикстуры `antigravity_user_status.json`; выбор модели с минимальным остатком (`0.9645665` → ~`3.54%` использовано, `96%` осталось); пропуск пустого `quotaInfo: {}` (`Gemini 4 Carbon`); `remainingFraction == nil` с `resetTime` → 0% остатка; истёкший `resetTime` → 100% остатка; неизвестные поля; пустой список моделей → пустой `[UsageWindow]`; битый JSON.
  - `AntigravityDaemonDiscoveryTests`: чтение `hub_*.json` из временного каталога (сортировка по `mtime`, пропуск битых файлов); `AntigravityHubInfo` `description`/`debugDescription`/`Mirror` → `"<redacted>"` (NFR-001).
  - `AntigravityProviderTests`: успех первого хаба; фоллбэк на второй хаб, если первый не отвечает; нет хабов → `.noData`; 401/403 → `.notAuthenticated`; битый JSON → `.error(invalidFormat)`; проверка заголовков и loopback-хоста.
  - `LimitsStoreTests` / `ResetFormatterTests` / `ProviderBrandingTests`: изоляция сбоя (NFR-003), подпись `WindowKind.overall`, непустой SVG логотипа.
- **Ручная приёмка:** US-1…US-3 в `build/LimitsWidget.app`, `swift build -c release` без предупреждений.

## Риски
| Риск | Вероятность | Митигация |
|------|-------------|-----------|
| Устаревшие `hub_*.json` от ранее закрытых окон | высокая | Пробуем файлы по убыванию `mtime`, при ошибке соединения переходим к следующему |
| Antigravity закрыт полностью | средняя | Возвращаем `.noData`; если ранее был снимок, `LimitsStore` показывает его с «данные устарели» |
| Смена формата `GetUserStatus` в обновлениях Antigravity | средняя | Толерантный декодер, статус «Формат ответа изменился», Claude/Codex продолжают работать |

## Проверка конституции
- **I. SDD** ✅ — спека → план → задачи → утверждение владельцем → реализация.
- **II. Безопасность** ✅ — только чтение, без внешней сети (II.4), `csrfToken` скрыт (`<redacted>`), персональные поля не декодируются, самоподписанный TLS ограничен строго `127.0.0.1` без редиректов.
- **III. Нативность** ✅ — Swift 6, только системные фреймворки, без сторонних зависимостей.
- **IV. Расширяемость** ✅ — `AntigravityProvider: LimitsProvider`, общий `WindowKind.overall`.
- **V. Тестируемость** ✅ — протоколы для discovery и локального RPC, обезличенная фикстура.

## Отклонения (заполняется при реализации)
- **D-1 (2026-11-20, пересмотр Q-2 владельцем):** Основной RPC-метод переведён на `RetrieveUserQuotaSummary` (показывает все 5 окон: `Gemini · 5 ч`, `Gemini · Неделя`, `Claude & GPT · 5 ч`, `Claude & GPT · Неделя`, `Gemini 4 Argon · Неделя` через новый `WindowKind.named(String)`); `GetUserStatus` оставлен фоллбэком при 404/501 или пустом ответе. Добавлен `AntigravityQuotaSummaryResponse` и фикстура `antigravity_quota_summary.json`.
