#!/usr/bin/env bash
# create-worktrees.sh — create a git worktree per squad task.
#
# Usage:  create-worktrees.sh <manifest-path>
#
# Reads the manifest, checks that the parent repo is clean and that
# task ids are unique, creates one worktree per task at
# <repo-parent>/<repo>-worktrees/<run-id>/<task-id> on a
# squad/<run-id>/<task-id> branch from base_ref, applies
# worktree.symlinkDirectories and worktree.sparsePaths from
# .claude/settings.json if set, and writes the worktree map to
# .claude/squad/runs/<run-id>/worktree-map.json. Also ensures
# <run_dir>/returns/ exists so children can write their return JSON.

set -euo pipefail

err() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || err "git not on PATH"
command -v jq  >/dev/null 2>&1 || err "jq not on PATH"

[ $# -eq 1 ] || err "usage: create-worktrees.sh <manifest-path>"
manifest="$1"
[ -f "$manifest" ] || err "manifest not found: $manifest"

repo_root="$(git rev-parse --show-toplevel)"
run_id=$(jq -r '.run_id' "$manifest")
base_ref=$(jq -r '.base_ref' "$manifest")
[ -n "$run_id" ] && [ "$run_id" != "null" ] || err "manifest missing run_id"
[ -n "$base_ref" ] && [ "$base_ref" != "null" ] || err "manifest missing base_ref"

git rev-parse --verify --quiet "$base_ref" >/dev/null || err "base_ref not a valid ref: $base_ref"

# Parent repo must be clean.
dirty=$(git -C "$repo_root" status --porcelain)
[ -z "$dirty" ] || { printf 'error: parent checkout is dirty:\n%s\n' "$dirty" >&2; exit 2; }

# Unique task ids.
id_count=$(jq '.tasks | length' "$manifest")
uniq_count=$(jq -r '.tasks[].id' "$manifest" | sort -u | wc -l | tr -d ' ')
[ "$id_count" -eq "$uniq_count" ] || err "manifest has duplicate task ids"

# Optional worktree settings from the consumer repo.
settings_file="$repo_root/.claude/settings.json"
symlink_dirs_json="[]"
sparse_paths_json="[]"
if [ -f "$settings_file" ]; then
  symlink_dirs_json=$(jq -c '(.worktree.symlinkDirectories // [])' "$settings_file")
  sparse_paths_json=$(jq -c '(.worktree.sparsePaths // [])' "$settings_file")
fi

parent_dir=$(dirname "$repo_root")
repo_name=$(basename "$repo_root")
wt_root="$parent_dir/${repo_name}-worktrees"
wt_parent="$wt_root/$run_id"
mkdir -p "$wt_parent"

run_dir="$repo_root/.claude/squad/runs/$run_id"
mkdir -p "$run_dir" "$run_dir/returns"
map_file="$run_dir/worktree-map.json"

# Archive any prior map so we never silently overwrite.
if [ -e "$map_file" ]; then
  mv "$map_file" "$map_file.archived-$(date -u +%Y%m%dT%H%M%SZ)"
fi

entries_json="{}"

task_ids=$(jq -r '.tasks[].id' "$manifest")
for tid in $task_ids; do
  branch="squad/$run_id/$tid"
  wt_path="$wt_parent/$tid"

  [ ! -e "$wt_path" ] || err "worktree path already exists: $wt_path"
  ! git show-ref --verify --quiet "refs/heads/$branch" || err "branch already exists: $branch"

  git worktree add "$wt_path" -b "$branch" "$base_ref" >/dev/null

  # Sparse paths.
  if [ "$(jq 'length' <<<"$sparse_paths_json")" -gt 0 ]; then
    paths=()
    while IFS= read -r p; do [ -n "$p" ] && paths+=("$p"); done < <(jq -r '.[]' <<<"$sparse_paths_json")
    if [ ${#paths[@]} -gt 0 ]; then
      ( cd "$wt_path" && git sparse-checkout init --cone >/dev/null && git sparse-checkout set "${paths[@]}" >/dev/null )
    fi
  fi

  # Symlink directories.
  symlinks_json="[]"
  if [ "$(jq 'length' <<<"$symlink_dirs_json")" -gt 0 ]; then
    while IFS= read -r sd; do
      [ -z "$sd" ] && continue
      src="$repo_root/$sd"
      dst="$wt_path/$sd"
      if [ -e "$src" ] && [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
        symlinks_json=$(jq -c --arg p "$sd" '. + [$p]' <<<"$symlinks_json")
      fi
    done < <(jq -r '.[]' <<<"$symlink_dirs_json")
  fi

  entries_json=$(jq -c \
    --arg tid "$tid" \
    --arg wtp "$wt_path" \
    --arg bn "$branch" \
    --arg br "$base_ref" \
    --argjson sl "$symlinks_json" \
    '. + {($tid): {
        worktree_path: $wtp,
        branch_name: $bn,
        base_ref: $br,
        symlinks: $sl
      }}' <<<"$entries_json")
done

jq -n \
  --arg rid "$run_id" \
  --arg pr "$repo_root" \
  --arg br "$base_ref" \
  --argjson entries "$entries_json" \
  '{run_id: $rid, base_ref: $br, parent_repo: $pr, entries: $entries}' > "$map_file"

printf 'wrote %s\n' "$map_file"
jq '.' "$map_file"
