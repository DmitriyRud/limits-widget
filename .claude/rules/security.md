---
paths:
  - "Sources/LimitsCore/Providers/**"
  - "Tests/LimitsCoreTests/Fixtures/**"
---

# Правила безопасности учётных данных

Реализуют принцип II конституции.

1. Типы с токенами (`ClaudeCredentials`, `CodexAuth`) переопределяют `description`/`debugDescription`
   → `"<redacted>"` и не реализуют `Encodable`.
2. Токен живёт только в локальной переменной на время одного запроса. Не кэшировать в свойствах, `UserDefaults`, файлах.
3. Запросы — только через `HTTPClient` с allowlist хостов: `api.anthropic.com`, `chatgpt.com`. Любой другой хост → ошибка.
4. Логи (`os.Logger`): только статус-коды и названия провайдеров. Никаких заголовков, тел запросов/ответов целиком.
5. Учётные данные открываются только на чтение. Запрещены `SecItemUpdate`, `SecItemDelete`, запись в `~/.codex`, `~/.claude`.
6. Фикстуры: обезличены. Заменять `account_id`, email, UUID, токены на `"REDACTED"`. Хук `post-edit-check` ищет
   паттерны `sk-ant-`, `eyJ…` (JWT), `Bearer ` с длинной строкой и блокирует их.
7. Чтение Keychain — через `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`
   в `Process`; stdout сразу декодируется, `Pipe` закрывается, строка не логируется.
