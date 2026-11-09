#!/usr/bin/env bash
# SessionStart: выводит в контекст агента состояние SDD — фичи, статусы, прогресс задач, следующую задачу.
set -uo pipefail
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0

echo "## SDD-состояние проекта"
for dir in specs/[0-9][0-9][0-9]-*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  st() { grep -m1 -E '^status:' "$dir/$1" 2>/dev/null | awk '{print $2}'; }
  line="- $name: spec=$(st spec.md) plan=$(st plan.md) tasks=$(st tasks.md)"
  if [[ -f "$dir/tasks.md" ]]; then
    done_n=$(grep -cE '^- \[x\] T[0-9]+' "$dir/tasks.md")
    total=$(grep -cE '^- \[[ x]\] T[0-9]+' "$dir/tasks.md")
    next=$(grep -m1 -E '^- \[ \] T[0-9]+' "$dir/tasks.md" | sed 's/^- \[ \] //')
    line+=" · задачи $done_n/$total"
    [[ -n "$next" ]] && line+=" · следующая: $next"
  fi
  echo "$line"
done
echo "Правки в Sources/ разрешены только при tasks.md status: approved (хук spec-gate)."
exit 0
