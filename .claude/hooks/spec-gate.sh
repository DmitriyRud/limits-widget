#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): правки в Sources/ разрешены, только если есть утверждённый tasks.md.
# Конституция, принцип I. Отключить для разовой правки: SDD_GATE=off в окружении сессии.
set -uo pipefail

[[ "${SDD_GATE:-on}" == "off" ]] && exit 0

input=$(cat)
path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
rel="${path#"$root"/}"

[[ "$rel" == Sources/* ]] || exit 0

if grep -lsE '^status:[[:space:]]*approved' "$root"/specs/*/tasks.md >/dev/null; then
  exit 0
fi

cat >&2 <<'MSG'
spec-gate: нет утверждённого tasks.md (status: approved) ни в одной папке specs/.
Правки в Sources/ запрещены до утверждения плана человеком (SDD, конституция I.1).
Действия: доработай spec/plan/tasks через /sdd-specify, /sdd-plan, /sdd-tasks и попроси пользователя
поменять status на approved.
MSG
exit 2
