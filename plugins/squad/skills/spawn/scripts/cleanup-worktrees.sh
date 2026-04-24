#!/usr/bin/env bash
# cleanup-worktrees.sh — remove squad worktrees and squad-prefixed
# branches for a given run, then archive the run dir.
#
# Usage:  cleanup-worktrees.sh <run-id>
#
# Refuses to --force anything. Dirty worktrees escalate (exit 2).

set -euo pipefail

err() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || err "git not on PATH"
command -v jq  >/dev/null 2>&1 || err "jq not on PATH"

[ $# -eq 1 ] || err "usage: cleanup-worktrees.sh <run-id>"
run_id="$1"

# Refuse to run from inside a linked worktree — we'd resolve run_dir
# against the wrong tree and refuse to touch squad/-prefixed branches
# that live on the primary checkout.
git_dir=$(cd "$(git rev-parse --git-dir)" && pwd)
git_common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd)
[ "$git_dir" = "$git_common_dir" ] || err "run from the primary worktree, not a linked worktree: $(git rev-parse --show-toplevel)"

repo_root="$(git rev-parse --show-toplevel)"
run_dir="$repo_root/.claude/squad/runs/$run_id"
map_file="$run_dir/worktree-map.json"

[ -d "$run_dir" ] || err "run directory not found: $run_dir"
[ -f "$map_file" ] || err "worktree map not found: $map_file"

task_ids=$(jq -r '.entries | keys[]' "$map_file")

# Dry-run check: any dirty worktree aborts cleanup before we mutate anything.
for tid in $task_ids; do
  wt_path=$(jq -r --arg t "$tid" '.entries[$t].worktree_path' "$map_file")
  branch_name=$(jq -r --arg t "$tid" '.entries[$t].branch_name' "$map_file")

  case "$branch_name" in
    squad/*) ;;
    *) err "refusing to touch non-squad branch: $branch_name" ;;
  esac

  if [ -d "$wt_path" ]; then
    dirty=$(git -C "$wt_path" status --porcelain 2>/dev/null || true)
    if [ -n "$dirty" ]; then
      printf 'error: worktree is dirty: %s (task %s)\n%s\n' "$wt_path" "$tid" "$dirty" >&2
      exit 2
    fi
  fi
done

# Actually remove.
for tid in $task_ids; do
  wt_path=$(jq -r --arg t "$tid" '.entries[$t].worktree_path' "$map_file")
  branch_name=$(jq -r --arg t "$tid" '.entries[$t].branch_name' "$map_file")

  if [ -d "$wt_path" ]; then
    git worktree remove "$wt_path" >/dev/null
    printf 'removed worktree: %s\n' "$wt_path"
  fi

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git branch -D "$branch_name" >/dev/null
    printf 'deleted branch:   %s\n' "$branch_name"
  fi

  incoming_ref="refs/squad-incoming/$run_id/$tid"
  if git show-ref --verify --quiet "$incoming_ref"; then
    git update-ref -d "$incoming_ref"
  fi
done

# Prune the per-run subdir, then the worktrees root if it's empty.
parent_dir=$(dirname "$repo_root")
repo_name=$(basename "$repo_root")
wt_root="$parent_dir/${repo_name}-worktrees"
wt_parent="$wt_root/$run_id"
if [ -d "$wt_parent" ] && [ -z "$(ls -A "$wt_parent" 2>/dev/null)" ]; then
  rmdir "$wt_parent"
fi
if [ -d "$wt_root" ] && [ -z "$(ls -A "$wt_root" 2>/dev/null)" ]; then
  rmdir "$wt_root"
fi

# Archive the run directory.
archived_root="$repo_root/.claude/squad/runs/_archived"
mkdir -p "$archived_root"
ts=$(date -u +%Y%m%dT%H%M%SZ)
mv "$run_dir" "$archived_root/${run_id}-${ts}"
printf 'archived run dir: %s\n' "$archived_root/${run_id}-${ts}"

git worktree prune
