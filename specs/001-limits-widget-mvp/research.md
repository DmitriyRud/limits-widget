# Исследование источников данных (001)

Статус фактов: ✅ проверено на машине разработчика (2026-11-09) · ⚠️ требует проверки.
Правило: при проверке **не выводить токены в консоль/контекст** (хук `protect-secrets` это блокирует).

## R-1. Claude Code

**Учётные данные** ✅
- macOS: Keychain, generic password, service = `Claude Code-credentials`, account = имя пользователя.
  Значение — JSON: `{"claudeAiOauth": {"accessToken", "refreshToken", "expiresAt", "scopes", "subscriptionType"}}`.
- Фоллбэк (Linux/старые версии): `~/.claude/.credentials.json` с той же структурой. ⚠️

**Лимиты** ⚠️ (недокументированный эндпоинт, его же использует `/usage` в Claude Code)
```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <accessToken>
anthropic-beta: oauth-2025-04-20
```
Ожидаемый ответ (обезличенная фикстура — `Tests/LimitsCoreTests/Fixtures/claude_usage.json`):
```json
{
  "five_hour":        {"utilization": 42.0, "resets_at": "2026-11-09T21:00:00.000000+00:00"},
  "seven_day":        {"utilization": 18.0, "resets_at": "2026-11-14T08:00:00.000000+00:00"},
  "seven_day_opus":   null,
  "seven_day_sonnet": {"utilization": 9.0,  "resets_at": "2026-11-14T08:00:00.000000+00:00"}
}
```
- `utilization` — проценты 0–100. Окно может быть `null` → не показываем.
- 401 → токен истёк → статус «Требуется вход в Claude Code» (refresh не делаем — non-goal).
- Риск принят владельцем (Q-1, 2026-11-09). Эндпоинт может измениться. Митигация: декодер толерантен к неизвестным полям, ошибка
  парсинга → статус «Формат ответа изменился», остальные провайдеры работают.

## R-2. Codex CLI

**Учётные данные** ✅ `~/.codex/auth.json` (поля `tokens.access_token`, `tokens.account_id`, `OPENAI_API_KEY`).

**Лимиты — локальный источник** ✅ (без сети, приоритетный)
Файлы `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`; строка-событие: `{"timestamp": "<ISO8601>", "type": …,
"payload": {"type": "token_count", "rate_limits": {…}}}` ✅ (проверено 2026-11-09). `timestamp` → `fetchedAt` (FR-008).
Содержимое `payload.rate_limits`:
```json
"rate_limits": {
  "limit_id": "codex",
  "primary":   {"used_percent": 38.0,  "window_minutes": 300,   "resets_at": 1793990035},
  "secondary": {"used_percent": 100.0, "window_minutes": 10080, "resets_at": 1794223159},
  "credits":   {"has_credits": false, "unlimited": false, "balance": "0"}
}
```
- `resets_at` — Unix-время (секунды). `window_minutes` определяет подпись окна (300 → «5 ч», 10080 → «Неделя»).
- Берём **последнее** событие с `rate_limits` из самого свежего файла (по mtime).
- Ограничение: данные актуальны на момент последнего запроса Codex. Если `resets_at` прошёл — окно
  считаем сброшенным (FR-012).

- ✅ (2026-11-09) Наблюдение при первом запуске: последние `rate_limits` в логах — от 2026-11-06 13:41Z, оба окна с тех пор
  сброшены (виджет показывает 0% использования). SQLite-базы `~/.codex/*.sqlite` тоже не менялись с 2026-11-06 —
  других локальных источников свежее нет. Если Codex используется вне этой машины (веб, Cloud, другой Mac), локальные
  логи этого не отражают — это ограничение решения Q-2; закрывается только сетевым источником (спека 002).

**Лимиты — сетевой источник** ✅ (проверено 2026-11-09 скриптом владельца, ответ обезличен;
основной источник после пересмотра Q-2)
```
GET https://chatgpt.com/backend-api/wham/usage
Authorization: Bearer <tokens.access_token>
ChatGPT-Account-Id: <tokens.account_id>
```
→ `HTTP 200 application/json`, фикстура `Tests/LimitsCoreTests/Fixtures/codex_usage.json`:
```json
"plan_type": "plus",
"rate_limit": {
  "allowed": true, "limit_reached": false,
  "primary_window":   {"used_percent": 0,  "limit_window_seconds": 18000,  "reset_after_seconds": 18000,  "reset_at": 1794267824},
  "secondary_window": {"used_percent": 14, "limit_window_seconds": 604800, "reset_after_seconds": 579221, "reset_at": 1794829044}
},
"code_review_rate_limit": null, "additional_rate_limits": null, "credits": {…}, "spend_control": {…}
```
- `used_percent` — проценты (в ответе целое, декодировать как Double); `limit_window_seconds / 60` → `WindowKind`
  (18000 с = 300 мин → 5 ч, 604800 с = 10080 мин → неделя); `reset_at` — Unix-время (секунды).
- Окна могут быть `null` → не показываем. `code_review_rate_limit` и `additional_rate_limits` в MVP не показываем
  (формат при непустом значении не проверен ⚠️).
- В ответе есть `user_id`, `account_id`, `email` — персональные данные: не декодировать, не логировать.
- Наблюдение: по сети недельное окно — 14%, а последний локальный лог (2026-11-06) уже сброшен —
  использование Codex вне этой машины локальные логи не отражают. Поэтому сеть — основной источник.
- Учётные данные: читаются только `tokens.access_token` и `tokens.account_id` из `~/.codex/auth.json`
  (только чтение, refresh не делаем; при 401 — фоллбэк на локальные логи). Структуру файла агент сам не проверял
  (доступ запрещён настройками владельца); поля подтверждены успешным запуском скрипта владельцем.

## R-3. Доступ к Keychain
- Чтение чужого generic-password элемента через `SecItemCopyMatching` вызывает системный диалог
  доступа при первом запуске; пользователь нажимает «Всегда разрешать». ⚠️ проверить поведение
  для неподписанной сборки (ad-hoc подпись меняется при каждой пересборке → диалог повторяется).
- Альтернатива для разработки: `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`
  через `Process` (разрешение выдаётся `security`, а не нашему бинарнику). Решение — в plan.md.
- Владелец согласен на однократный системный диалог «Всегда разрешать» (Q-3, 2026-11-09).
  ✅ (2026-11-09, первый запуск `build/LimitsWidget.app`): чтение через `/usr/bin/security` прошло **без системного
  диалога** — доступ к элементу уже был выдан `security` ранее; данные Claude совпали с `/usage`.

## R-4. Форма виджета
См. `docs/adr/0001-desktop-window-instead-of-widgetkit.md`.
