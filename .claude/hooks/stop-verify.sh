#!/usr/bin/env bash
# Stop: если в рабочем дереве изменены Swift-файлы, проверяем, что пакет собирается и тесты проходят.
# Падение → exit 2, агент продолжает работу и чинит. Защита от зацикливания — stop_hook_active.
set -uo pipefail

input=$(cat)
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0

changed=$(git status --porcelain -- '*.swift' 'Package.swift' 2>/dev/null)
[[ -z "$changed" ]] && exit 0

if ! out=$(swift build 2>&1); then
  echo "stop-verify: swift build упал после твоих изменений. Исправь перед завершением:" >&2
  grep -E 'error:' <<<"$out" | head -20 >&2
  exit 2
fi

if ! out=$(scripts/test.sh 2>&1); then
  echo "stop-verify: тесты упали. Исправь или явно сообщи пользователю, что это ожидаемо (TDD, фаза 2):" >&2
  grep -E '✘|error:|failed' <<<"$out" | head -20 >&2
  exit 2
fi
exit 0
