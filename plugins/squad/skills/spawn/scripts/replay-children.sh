#!/usr/bin/env bash
# replay-children.sh — cherry-pick each child's commits onto the
# integration branch in merge_order, running the per-task validation gate
# between children.
#
# Usage:
#   replay-children.sh <run-id>
#
# Preconditions:
#   - `.claude/squad/runs/<run-id>/manifest.json` exists
#   - `.claude/squad/runs/<run-id>/worktree-map.json` exists
#   - `.claude/squad/runs/<run-id>/returns/<task-id>.json` exists for every
#     task (missing returns are treated as failed and skipped)
#   - Caller has created branch `squad/<run-id>/integration` at the
#     manifest's base_ref and has switched to it
#
# On success: exits 0 and writes `.claude/squad/runs/<run-id>/squad-run.json`.
# On cherry-pick conflict: runs `git cherry-pick --abort`, writes the
# partial run summary, prints the unmerged paths, and exits 3 so the
# caller can choose auto-resolve or pause-and-ask.

set -euo pipefail

err() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || err "git not on PATH"
command -v jq  >/dev/null 2>&1 || err "jq not on PATH"

[ $# -eq 1 ] || err "usage: replay-children.sh <run-id>"

run_id="$1"
repo_root="$(git rev-parse --show-toplevel)"
run_dir="$repo_root/.claude/squad/runs/$run_id"
manifest="$run_dir/manifest.json"
map_file="$run_dir/worktree-map.json"
returns_dir="$run_dir/returns"
script_dir="$(cd "$(dirname "$0")" && pwd)"

[ -f "$manifest" ] || err "manifest not found: $manifest"
[ -f "$map_file" ] || err "worktree-map not found: $map_file"
[ -d "$returns_dir" ] || err "returns dir not found: $returns_dir"

integration_branch="squad/$run_id/integration"
cur_branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$cur_branch" = "$integration_branch" ] || err "expected branch $integration_branch, got $cur_branch"

# Build an ordered task-id list: ascending merge_order, tie-break by topological
# order of dependencies. We do a simple topo pass with merge_order as primary key.
ordered_ids=$(
  jq -r '
    .tasks
    | map({id, merge_order, dependencies})
    | sort_by(.merge_order)
    | .[] | .id
  ' "$manifest"
)

summary_json='{"run_id":"","tasks":[]}'
summary_json=$(jq --arg rid "$run_id" '.run_id=$rid' <<<"$summary_json")

exit_code=0

for tid in $ordered_ids; do
  return_file="$returns_dir/$tid.json"

  if [ ! -f "$return_file" ]; then
    summary_json=$(jq --arg t "$tid" --arg r "missing-return" \
      '.tasks += [{id:$t,outcome:"skipped",reason:$r,picked:[]}]' <<<"$summary_json")
    printf 'skip task=%s reason=missing-return\n' "$tid" >&2
    continue
  fi

  status=$(jq -r '.status' "$return_file")
  if [ "$status" != "done" ]; then
    reason=$(jq -r '[.blockers[]?.kind] | join(",") // "failed"' "$return_file")
    summary_json=$(jq --arg t "$tid" --arg s "$status" --arg r "$reason" \
      '.tasks += [{id:$t,outcome:"skipped",reason:($s+":"+$r),picked:[]}]' <<<"$summary_json")
    printf 'skip task=%s status=%s\n' "$tid" "$status" >&2
    continue
  fi

  # Fetch the child's branch into a local ref we own.
  wt_path=$(jq -r --arg t "$tid" '.entries[$t].worktree_path // empty' "$map_file")
  branch_name=$(jq -r --arg t "$tid" '.entries[$t].branch_name // empty' "$map_file")
  incoming_ref="refs/squad-incoming/$run_id/$tid"

  if [ -n "$wt_path" ] && [ -n "$branch_name" ]; then
    git fetch "$wt_path" "${branch_name}:${incoming_ref}" >/dev/null
  fi

  # Cherry-pick each commit in the child's return.
  shas=$(jq -r '.commits[].sha' "$return_file")
  picked_json='[]'

  for sha in $shas; do
    if git cherry-pick "$sha" >/dev/null 2>&1; then
      picked_json=$(jq -c --arg s "$sha" '. + [$s]' <<<"$picked_json")
    else
      # Conflict or failure.
      unmerged=$(git diff --name-only --diff-filter=U)
      printf 'conflict task=%s sha=%s\n%s\n' "$tid" "$sha" "$unmerged" >&2
      git cherry-pick --abort >/dev/null 2>&1 || true
      summary_json=$(jq \
        --arg t "$tid" \
        --arg s "$sha" \
        --arg u "$unmerged" \
        --argjson picked "$picked_json" \
        '.tasks += [{id:$t,outcome:"conflict",failed_sha:$s,unmerged:($u|split("\n")),picked:$picked}]' \
        <<<"$summary_json")
      printf '%s\n' "$summary_json" > "$run_dir/squad-run.json"
      exit 3
    fi
  done

  # Run the validation gate.
  if bash "$script_dir/validate-gate.sh" "$run_id" "$tid" >/dev/null; then
    summary_json=$(jq --arg t "$tid" --argjson p "$picked_json" \
      '.tasks += [{id:$t,outcome:"picked",picked:$p,validation:"pass"}]' <<<"$summary_json")
    printf 'ok   task=%s picks=%s\n' "$tid" "$(jq 'length' <<<"$picked_json")" >&2
  else
    summary_json=$(jq --arg t "$tid" --argjson p "$picked_json" \
      '.tasks += [{id:$t,outcome:"validation-failed",picked:$p,validation:"fail"}]' <<<"$summary_json")
    printf 'gate-fail task=%s\n' "$tid" >&2
    exit_code=4
    # Do not revert; caller decides.
    break
  fi
done

printf '%s\n' "$summary_json" | jq '.' > "$run_dir/squad-run.json"
printf 'wrote %s\n' "$run_dir/squad-run.json"
exit "$exit_code"
