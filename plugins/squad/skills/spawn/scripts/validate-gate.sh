#!/usr/bin/env bash
# validate-gate.sh — run a task's validation_command from the integration
# branch working tree and report the outcome.
#
# Usage:
#   validate-gate.sh <run-id> <task-id>
#
# Reads `.claude/squad/runs/<run-id>/manifest.json`, finds the task's
# `validation_command`, runs it from the current cwd (which must be on
# the integration branch — caller's responsibility), and prints a one-line
# summary. Exits non-zero on validation failure.

set -euo pipefail

err() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || err "git not on PATH"
command -v jq  >/dev/null 2>&1 || err "jq not on PATH"

[ $# -eq 2 ] || err "usage: validate-gate.sh <run-id> <task-id>"

run_id="$1"
task_id="$2"

repo_root="$(git rev-parse --show-toplevel)"
manifest="$repo_root/.claude/squad/runs/$run_id/manifest.json"
[ -f "$manifest" ] || err "manifest not found: $manifest"

cmd=$(jq -r --arg t "$task_id" '.tasks[] | select(.id == $t) | .validation_command' "$manifest")
[ -n "$cmd" ] && [ "$cmd" != "null" ] || err "no validation_command for task $task_id"

cur_branch="$(git rev-parse --abbrev-ref HEAD)"
expected="squad/$run_id/integration"
if [ "$cur_branch" != "$expected" ]; then
  printf 'warn: current branch is %s, expected %s\n' "$cur_branch" "$expected" >&2
fi

printf 'validating task=%s cmd=%s\n' "$task_id" "$cmd" >&2
set +e
bash -c "$cmd"
rc=$?
set -e

if [ $rc -eq 0 ]; then
  printf 'gate-ok task=%s\n' "$task_id"
else
  printf 'gate-fail task=%s rc=%d\n' "$task_id" "$rc" >&2
  exit "$rc"
fi
