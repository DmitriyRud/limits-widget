#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit):
#  1) ищет в изменённом файле похожие на токены строки → exit 2 (агент обязан убрать);
#  2) форматирует .swift через `swift format`.
set -uo pipefail

input=$(cat)
path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
[[ -f "$path" ]] || exit 0

# Пропускаем сами хуки/правила — в них паттерны упоминаются намеренно.
case "$path" in
  */.claude/*|*/specs/*|*/docs/*|*CLAUDE.md) ;;
  *)
    if grep -nE 'sk-ant-[A-Za-z0-9_-]{10,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}|Bearer [A-Za-z0-9._-]{30,}|sk-[A-Za-z0-9]{32,}' "$path" >&2; then
      echo "post-edit-check: в $path найдена строка, похожая на токен (см. выше). Замени на \"REDACTED\" (конституция II.1)." >&2
      exit 2
    fi
    ;;
esac

if [[ "$path" == *.swift ]] && command -v swift >/dev/null; then
  swift format -i "$path" 2>/dev/null || true
fi
exit 0
