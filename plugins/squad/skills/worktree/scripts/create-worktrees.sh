#!/usr/bin/env bash
# create-worktrees.sh — create git worktrees for a squad task manifest.
#
# Usage:
#   create-worktrees.sh <manifest-path>
#
# Reads the manifest at <manifest-path>, validates the base_ref, creates one
# worktree per task with `worktree: true` on a `squad/<run-id>/<task-id>`
# branch, applies `.worktreeinclude` if present, symlinks directories listed
# in `.claude/settings.json` (`worktree.symlinkDirectories`), and writes the
# worktree map to `.claude/squad/runs/<run-id>/worktree-map.json`.
#
# Exits non-zero on any validation failure; never forces, never rewrites,
# never touches branches outside the `squad/*` prefix.

set -euo pipefail

err() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || err "git not on PATH"
command -v jq  >/dev/null 2>&1 || err "jq not on PATH"

[ $# -eq 1 ] || err "usage: create-worktrees.sh <manifest-path>"

manifest="$1"
[ -f "$manifest" ] || err "manifest not found: $manifest"

# Resolve repo root and run id.
repo_root="$(git rev-parse --show-toplevel)"
run_id="$(jq -r '.run_id' "$manifest")"
base_ref="$(jq -r '.base_ref' "$manifest")"
[ -n "$run_id" ] && [ "$run_id" != "null" ] || err "manifest missing run_id"
[ -n "$base_ref" ] && [ "$base_ref" != "null" ] || err "manifest missing base_ref"

git rev-parse --verify --quiet "$base_ref" >/dev/null || err "base_ref not a valid ref: $base_ref"

# Compute paths.
parent_dir="$(dirname "$repo_root")"
repo_name="$(basename "$repo_root")"
worktree_parent="$parent_dir/${repo_name}-worktrees"
mkdir -p "$worktree_parent"

run_dir="$repo_root/.claude/squad/runs/$run_id"
mkdir -p "$run_dir"

map_file="$run_dir/worktree-map.json"
if [ -e "$map_file" ]; then
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  mv "$map_file" "$map_file.archived-$ts"
fi

# Read optional symlink directories from repo settings.
settings_file="$repo_root/.claude/settings.json"
symlink_dirs_json="[]"
if [ -f "$settings_file" ]; then
  symlink_dirs_json="$(jq -c '(.worktree.symlinkDirectories // [])' "$settings_file")"
fi

# Optional .worktreeinclude list — simple line-by-line, skip blanks/comments.
wt_include="$repo_root/.worktreeinclude"
include_files=()
if [ -f "$wt_include" ]; then
  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
      '!'*) continue ;;  # exclusions handled by copy step below
      *) include_files+=("$line") ;;
    esac
  done < "$wt_include"
fi

# Build the entries and shared_cwd_tasks arrays.
entries_json="{}"
shared_cwd_json="[]"

task_count=$(jq '.tasks | length' "$manifest")
for i in $(seq 0 $((task_count - 1))); do
  task_id=$(jq -r ".tasks[$i].id" "$manifest")
  use_wt=$(jq -r ".tasks[$i].worktree" "$manifest")

  if [ "$use_wt" != "true" ]; then
    shared_cwd_json="$(jq -c --arg tid "$task_id" '. + [$tid]' <<<"$shared_cwd_json")"
    continue
  fi

  wt_name=$(jq -r ".tasks[$i].worktree_name" "$manifest")
  [ -n "$wt_name" ] && [ "$wt_name" != "null" ] || err "task $task_id is worktree: true but lacks worktree_name"

  branch_name="squad/$run_id/$task_id"
  wt_path="$worktree_parent/$wt_name"

  # Refuse if path exists and isn't a squad-owned worktree for this run.
  if [ -e "$wt_path" ]; then
    err "worktree path already exists: $wt_path"
  fi

  # Refuse if branch already exists.
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    err "branch already exists: $branch_name"
  fi

  git worktree add "$wt_path" -b "$branch_name" "$base_ref" >/dev/null

  # Apply .worktreeinclude (copy).
  include_applied=false
  copied_json="[]"
  if [ ${#include_files[@]} -gt 0 ]; then
    include_applied=true
    for rel in "${include_files[@]}"; do
      src="$repo_root/$rel"
      dst="$wt_path/$rel"
      if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -R "$src" "$dst"
        copied_json="$(jq -c --arg p "$rel" '. + [$p]' <<<"$copied_json")"
      fi
    done
  fi

  # Apply symlink directories.
  symlinks_json="[]"
  if [ "$(jq 'length' <<<"$symlink_dirs_json")" -gt 0 ]; then
    for sd in $(jq -r '.[]' <<<"$symlink_dirs_json"); do
      src="$repo_root/$sd"
      dst="$wt_path/$sd"
      if [ -e "$src" ] && [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
        symlinks_json="$(jq -c --arg p "$sd" '. + [$p]' <<<"$symlinks_json")"
      fi
    done
  fi

  created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  entries_json="$(jq -c \
    --arg tid "$task_id" \
    --arg wtp "$wt_path" \
    --arg bn "$branch_name" \
    --arg br "$base_ref" \
    --argjson incl "$include_applied" \
    --argjson sl "$symlinks_json" \
    --argjson cp "$copied_json" \
    --arg ca "$created_at" \
    '. + {($tid): {
        worktree_path: $wtp,
        branch_name: $bn,
        base_ref: $br,
        worktreeinclude_applied: $incl,
        symlinks: $sl,
        copied_files: $cp,
        cleanup_policy: "on-merge",
        created_at: $ca
      }}' <<<"$entries_json")"
done

# Emit the worktree map.
jq -n \
  --arg rid "$run_id" \
  --arg pr "$repo_root" \
  --argjson entries "$entries_json" \
  --argjson shared "$shared_cwd_json" \
  '{
    map_version: "1",
    run_id: $rid,
    parent_repo: $pr,
    entries: $entries,
    shared_cwd_tasks: $shared
  }' > "$map_file"

# Print the map and location.
printf 'wrote %s\n' "$map_file"
jq '.' "$map_file"
