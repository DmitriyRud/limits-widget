---
name: build-and-run
description: Собрать, протестировать и запустить виджет на этом Mac (debug или release .app-бандл). Использовать, когда пользователь просит запустить, собрать, проверить вживую.
argument-hint: "[test | run | release]"
---

# /build-and-run

- `test` (по умолчанию): `swift build` → `scripts/test.sh`. Покажи итог: число тестов, упавшие тесты с причиной.
- `run`: `swift run LimitsWidget` в фоне (`run_in_background`). Виджет появится на рабочем столе; лог — stdout.
  При первом запуске macOS спросит доступ к Keychain-элементу «Claude Code-credentials» — сообщи пользователю,
  что нужно нажать «Всегда разрешать».
- `release`: `swift build -c release`, затем `scripts/bundle.sh` (появится в задаче T035) → `build/LimitsWidget.app`.
  Для установки: `cp -R build/LimitsWidget.app /Applications/`.

Остановка запущенного виджета: `pkill -x LimitsWidget`.
Если сборка падает с `no such module 'Testing'` — тесты запущены не через `scripts/test.sh`.
