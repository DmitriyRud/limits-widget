---
paths:
  - "Tests/**"
---

# Правила тестов

- Фреймворк — Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`). XCTest не использовать.
- Запуск только через `scripts/test.sh`.
- Время в тестах фиксированное (`Date(timeIntervalSince1970:)`), никогда `Date()` / `.now` без инъекции.
- Сеть и Keychain — только фейки (`FakeHTTPClient`, `FakeCredentialSource`). Тесты не ходят в интернет и не читают `~`.
- Фикстуры — в `Tests/LimitsCoreTests/Fixtures/`, загружаются через `Bundle.module`. Имя: `<provider>_<case>.json|jsonl`.
- Имя теста описывает поведение: `expiredWindowHasZeroEffectivePercent`, а не `test1`.
- Для каждого парсера: happy path, `null`/отсутствующие поля, неизвестные поля, битый ввод.
- Параметризованные тесты: аргументы выносить в `static let` — иначе компилятор не успевает вывести типы.
