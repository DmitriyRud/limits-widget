---
name: add-provider
description: Добавить поддержку нового ИИ-агента (Gemini CLI, Cursor, и т.п.) в виджет лимитов. Запускает полный SDD-цикл для провайдера и задаёт шаблон реализации LimitsProvider.
argument-hint: "<название агента>"
---

# /add-provider — новый ИИ-агент

Новый провайдер — это отдельная фича SDD. Не пиши код сразу.

## 1. Исследование
Запусти субагента `provider-researcher` с агентом `$ARGUMENTS`. Нужно выяснить и записать в `research.md`:
- где хранятся учётные данные (файл / Keychain service) — **только структура, без значений**;
- есть ли локальный источник лимитов (логи сессий, кэш) и его формат;
- сетевой эндпоинт лимитов, заголовки, формат ответа;
- какие окна лимитов существуют (длина в минутах) и как выражен сброс (ISO-дата / Unix / секунды до сброса).

## 2. Спека
`/sdd-specify Поддержка <агент> в виджете лимитов` — FR по образцу FR-001…FR-004 из `specs/001-*/spec.md`.

## 3. Шаблон реализации (для plan.md)
```
Sources/LimitsCore/Providers/<Agent>/
  <Agent>Provider.swift      // struct: LimitsProvider; id = "<kebab>", displayName
  <Agent>Credentials.swift   // description → "<redacted>", без Encodable
  <Agent>UsageResponse.swift // Decodable, толерантный, → [UsageWindow]
Tests/LimitsCoreTests/
  <Agent>ProviderTests.swift
  Fixtures/<agent>_usage.json   // обезличенная
```
- Окна маппить в `WindowKind(windowMinutes:)`; модельные недельные окна → `.weeklyModel("<Model>")`.
- Хост провайдера добавить в allowlist `HTTPClient` (это изменение проверяет `security-reviewer`).
- Зарегистрировать провайдер в списке провайдеров приложения (одна строка) — UI менять не нужно.

## 4. Дальше
`/sdd-plan` → `/sdd-tasks` → утверждение человеком → `/sdd-implement`.
