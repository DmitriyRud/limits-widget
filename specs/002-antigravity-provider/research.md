# Исследование источников данных (002 — Antigravity)

Статус фактов: ✅ проверено на машине разработчика (2026-11-19) · ⚠️ требует проверки.
Правило: при проверке **не выводить токены в консоль/контекст** (конституция II.1).

## R-1. Установленные компоненты на машине ✅

- CLI `agy` установлен (`/opt/homebrew/bin/agy`, а также `~/.gemini/bin/agy`). В `agy --help` нет подкоманды для вывода квот/лимитов.
- Работает **Antigravity 2.0** (desktop-приложение) с фоновыми процессами:
  `~/.gemini/bin/agy --hub --hub-port=<port> --app_data_dir=antigravity`
- `~/Library/Application Support/Antigravity/User/globalStorage/state.vscdb` **отсутствует** (в каталоге только файл `credential-user-scope`).
- В Keychain нет сервисов с `antigravity`/`agy`; элемент `"gemini"` не содержит JSON OAuth-токена (`not json or empty`, проверено 2026-11-19 ✅).

## R-2. Основной источник — локальный `agy --hub` (loopback RPC) ✅

Метаданные активных инстансов лежат в `~/.gemini/antigravity/daemon/hub_<port>.json` (права `0600`).
Структура файла (`jq 'paths | join(".")'`, проверено 2026-11-19):
```json
{
  "csrfToken": "<REDACTED>",
  "httpPort": 52584,
  "httpsPort": 52583,
  "lsVersion": "...",
  "pid": 27765
}
```
- В каталоге может быть несколько `hub_*.json` (например, на каждый открытый проект/окно) — берём файлы в порядке убывания `mtime` и пробуем подключиться (или проверяем, что `pid` жив).
- Эндпоинт ✅ (проверено 2026-11-19):
  ```
  POST https://127.0.0.1:<httpsPort>/exa.language_server_pb.LanguageServerService/GetUserStatus
  Content-Type: application/json
  Connect-Protocol-Version: 1
  X-Codeium-Csrf-Token: <csrfToken>
  Body: {"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"}}
  ```
- Ответ `HTTP 200 application/json` ✅ (обезличенная фикстура — `Tests/LimitsCoreTests/Fixtures/antigravity_user_status.json`):
  - `userStatus` содержит персональные поля (`email`, `name`, `profilePictureUrl`) — **не декодировать и не логировать** (конституция II.1).
  - `userStatus.cascadeModelConfigData.clientModelConfigs[]` — массив моделей, у каждой `label` и `quotaInfo`:
    ```json
    {
      "label": "Gemini 4 Neon (High)",
      "quotaInfo": {
        "remainingFraction": 0.9645665,
        "resetTime": "2026-11-20T02:12:51Z"
      }
    }
    ```
  - **Важный крайний случай из реального ответа:** у части моделей (например, `"Gemini 4 Carbon"`) приходит `"quotaInfo": {}` (нет ни `remainingFraction`, ни `resetTime`) → такие записи **пропускать**, не считать 0%.
  - Если `remainingFraction` отсутствует, но `resetTime` задан → protobuf v3 zero-omission, считать `remainingFraction = 0.0`.
  - Если `resetTime` в прошлом (`<= now`) → окно сброшено, `remainingFraction = 1.0`.
  - `resetTime` — ISO 8601 UTC (`"2026-11-20T02:12:51Z"`).

## R-3. Облачный фоллбэк (Google Cloud Code Assist) ⚠️

- `POST https://cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels` (или `daily-cloudcode-pa.googleapis.com`).
- В Antigravity 2.0 `state.vscdb` отсутствует; единственный кандидат в Keychain — сервис `"gemini"` (структура значения не подтверждена ⚠️).
- До подтверждения источника OAuth-токена облачный фоллбэк не может читать токен напрямую; если Antigravity закрыт (`daemon/hub_*.json` отсутствует или процесс не отвечает), провайдер возвращает `.noData` (при этом `LimitsStore` сохраняет последний удачный снимок с пометкой «данные устарели», если виджет уже успел обновиться).

## R-4. Модель квот Antigravity ✅

Реальные пулы в ответе `GetUserStatus` (2026-11-19):
- Семейства Gemini 4 Neon / Hydrogen / 3.8 Flash / Orchestrator (Neon) — 5-часовое окно (`remainingFraction: 0.9645665`, `resetTime: +~4–5 ч`).
- Семейство Gemini 4 Argon / Orchestrator (Argon) — недельное окно (`resetTime: +7 дн`).
- Claude Opus/Sonnet 5.5 / GPT-OSS 120B — 5-часовое окно.
- По решению владельца (Q-2) все валидные модели агрегируются в **один общий индикатор** (минимум `remainingFraction` среди моделей с квотой, и его `resetTime`).

## R-5. Логотип (ProviderBranding)

Монохромный SVG-логотип (`viewBox="0 0 24 24"`) и фирменный цвет (`tintRGB`) в `AntigravityProvider+Branding.swift` — по аналогии с `ClaudeCodeProvider+Branding.swift` и `CodexProvider+Branding.swift`.
