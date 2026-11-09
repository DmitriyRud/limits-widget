#!/usr/bin/env bash
# PreToolUse (Bash|Read|Grep|Edit|Write): не даёт агенту прочитать или вывести учётные данные ИИ-агентов.
# Конституция, принцип II. Exit 2 → вызов блокируется, stderr уходит агенту.
set -uo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

deny() {
  echo "protect-secrets: заблокировано — $1. Используй /probe-source: смотри только структуру (jq paths), не значения." >&2
  exit 2
}

SECRET_FILES='(\.codex/auth\.json|\.claude/\.credentials\.json)'

case "$tool" in
  Read|Edit|Write)
    path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
    [[ "$path" =~ $SECRET_FILES ]] && deny "доступ к файлу учётных данных $path"
    ;;
  Grep)
    path=$(jq -r '.tool_input.path // ""' <<<"$input")
    [[ "$path" =~ $SECRET_FILES ]] && deny "поиск по файлу учётных данных"
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    # Пароль из Keychain в stdout
    if [[ "$cmd" =~ find-generic-password ]] && [[ "$cmd" =~ (^|[[:space:]])-[a-zA-Z]*[wg] ]]; then
      deny "вывод пароля из Keychain (флаги -w/-g)"
    fi
    if [[ "$cmd" =~ $SECRET_FILES ]]; then
      # Разрешено: только пути ключей через jq paths, проверка существования
      if [[ "$cmd" =~ jq[[:space:]].*paths ]] || [[ "$cmd" =~ (test|\[)[[:space:]]+-[ef][[:space:]] ]] || [[ "$cmd" =~ ls[[:space:]] ]]; then
        exit 0
      fi
      deny "команда обращается к файлу учётных данных"
    fi
    ;;
esac
exit 0
