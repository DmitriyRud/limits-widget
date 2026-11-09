#!/usr/bin/env bash
# Запуск тестов. Если установлены только Command Line Tools (без Xcode),
# Swift Testing лежит вне стандартного пути — добавляем его явно.
set -euo pipefail
cd "$(dirname "$0")/.."

CLT_FRAMEWORKS=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
EXTRA=()
if [[ "$(xcode-select -p)" == /Library/Developer/CommandLineTools* && -d "$CLT_FRAMEWORKS/Testing.framework" ]]; then
  EXTRA=(-Xswiftc -F -Xswiftc "$CLT_FRAMEWORKS"
         -Xlinker -F -Xlinker "$CLT_FRAMEWORKS"
         -Xlinker -rpath -Xlinker "$CLT_FRAMEWORKS"
         -Xlinker -rpath -Xlinker "${CLT_FRAMEWORKS%/Frameworks}/usr/lib")
fi

exec swift test ${EXTRA[@]+"${EXTRA[@]}"} "$@"
