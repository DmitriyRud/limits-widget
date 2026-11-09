---
name: probe-source
description: Безопасно проверить формат источника данных о лимитах (файл, лог, Keychain, HTTP-ответ) на этой машине и сохранить обезличенную фикстуру. Использовать при исследовании провайдера или когда тест/парсер расходится с реальностью.
argument-hint: "<claude | codex | путь к файлу>"
---

# /probe-source — безопасная проверка источника

Цель — узнать **структуру**, не увидев секретов. Хук `protect-secrets` блокирует прямое чтение файлов с токенами.

## Разрешённые приёмы
- Структура JSON без значений: `jq -r 'paths(scalars)|map(tostring)|join(".")' <file> | sort -u`
- Наличие Keychain-элемента без пароля: `security find-generic-password -s "<service>" >/dev/null && echo present`
- Логи сессий Codex (секретов не содержат): `grep -o '"rate_limits":{[^}]*}[^}]*}[^}]*}' <файл> | tail -1`
- HTTP-ответ: писать отдельный скрипт в scratchpad, который читает токен сам и печатает **только тело ответа**,
  пропущенное через обезличивание (`jq 'walk(if type=="string" and length>40 then "REDACTED" else . end)'`).

## Запрещено
- `cat`/`Read` файлов `auth.json`, `.credentials.json`; `security ... -w` с выводом в консоль; печать заголовков запроса.

## Результат
1. Обнови `specs/<NNN>/research.md`: факт, ✅ и дата.
2. Сохрани обезличенный пример в `Tests/LimitsCoreTests/Fixtures/<provider>_<case>.json[l]`
   (хук `post-edit-check` проверит отсутствие токенов).
