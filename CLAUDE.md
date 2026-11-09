# Limits Widget

macOS-виджет на рабочем столе: показывает процент использования и время до сброса
5-часовых («дневных») и недельных лимитов авторизованных ИИ-агентов (Claude Code, Codex CLI).

## Главное
- Процесс — **Spec-Driven Development**. Сначала прочитай `specs/constitution.md`; она главнее этого файла.
- Активная фича: `specs/001-limits-widget-mvp/` (`spec.md` → `plan.md` → `tasks.md`, факты об источниках данных — в `research.md`).
- Код в `Sources/` правится только когда `tasks.md` активной фичи имеет `status: approved`
  (это проверяет хук `spec-gate`). Статус меняет человек, не агент.
- Подробные правила лежат в `.claude/rules/` и подгружаются по путям файлов.

## Команды
- Сборка: `swift build`
- Тесты: `scripts/test.sh` (не `swift test` напрямую: при наличии только Command Line Tools скрипт подключает Swift Testing)
- Запуск: `swift run LimitsWidget`
- Форматирование: `swift format -i -r Sources Tests` (после правок `.swift` запускается хуком)

## Структура
- `Sources/LimitsCore/` — модели, провайдеры, форматирование. Без AppKit/SwiftUI, всё тестируется.
- `Sources/LimitsWidget/` — AppKit/SwiftUI-оболочка (окно на уровне рабочего стола, menu bar). Решение — в `docs/adr/0001-*.md`.
- `Tests/LimitsCoreTests/` — Swift Testing, фикстуры в `Fixtures/`.
- `specs/` — SDD: конституция, шаблоны, папка на каждую фичу `NNN-name/`.
- `docs/adr/` — архитектурные решения.

## Процесс (скиллы)
`/sdd-specify` → `/sdd-plan` → `/sdd-tasks` → (человек утверждает) → `/sdd-implement`.
Новый ИИ-агент — `/add-provider`. Проверка источника данных — `/probe-source`. Сборка и запуск — `/build-and-run`.

## Субагенты
`spec-writer`, `architect`, `swift-implementer`, `test-writer`, `security-reviewer`, `provider-researcher` — см. `.claude/agents/`.

## Жёсткие запреты
- Никогда не выводить содержимое `~/.codex/auth.json`, `~/.claude/.credentials.json` и Keychain-элемента
  `Claude Code-credentials` (хук `protect-secrets` блокирует такие команды). Для проверки структуры —
  только имена ключей (`jq 'paths|join(".")'`), не значения.
- Не изменять учётные данные агентов, не делать refresh токенов.
- Не добавлять SPM-зависимости без ADR.
