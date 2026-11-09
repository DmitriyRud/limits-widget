---
paths:
  - "Sources/**/*.swift"
  - "Tests/**/*.swift"
  - "Package.swift"
---

# Правила Swift-кода

- Swift 6, strict concurrency. Никаких `@unchecked Sendable` и `nonisolated(unsafe)` без комментария-обоснования.
- Модели — `struct`, `Sendable`, `Hashable`; публичные `init` явные.
- Состояние UI — `@Observable` + `@MainActor`. Сетевые/файловые операции — `async`, вне главного актора.
- `LimitsCore` не импортирует `AppKit`, `SwiftUI`, `WidgetKit`. Всё, что зависит от ОС (Keychain, `Process`, сеть), — за протоколом.
- Провайдеры не бросают ошибки наружу: результат всегда `ProviderSnapshot` со статусом.
- Даты: из API парсить через `ISO8601DateFormatter` с `.withFractionalSeconds`; Unix-время — `Date(timeIntervalSince1970:)`.
- Декодеры толерантны: неизвестные поля игнорируются, опциональные окна — `Optional`.
- Пользовательские строки — на русском, в одном месте (`ResetFormatter`/View), не размазывать по провайдерам.
- Без `print` в `LimitsCore`; для диагностики — `os.Logger` с `privacy: .private` для любых данных пользователя.
- Без force unwrap (`!`) и `try!` вне тестов.
- Каждый публичный тип — с doc-комментарием, где указано требование (`FR-xxx`), которое он реализует.
