#!/usr/bin/env bash

set -eu

remote_name="${1:-origin}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf 'STATUS=not-a-git-repo\n'
  exit 1
fi

if ! remote_url="$(git remote get-url "$remote_name" 2>/dev/null)"; then
  printf 'REMOTE_NAME=%s\n' "$remote_name"
  printf 'STATUS=no-remote\n'
  exit 1
fi

remote_host='unknown'
forge='unknown'

case "$remote_url" in
  git@*:* )
    remote_host="${remote_url#git@}"
    remote_host="${remote_host%%:*}"
    ;;
  ssh://* )
    remote_host="${remote_url#ssh://}"
    remote_host="${remote_host#*@}"
    remote_host="${remote_host%%/*}"
    ;;
  http://* | https://* )
    remote_host="${remote_url#*://}"
    remote_host="${remote_host#*@}"
    remote_host="${remote_host%%/*}"
    ;;
esac

case "${remote_host}" in
  github.com | *.github.com | github.* | *.github.* )
    forge='github'
    ;;
  gitlab.com | *.gitlab.com | gitlab.* | *.gitlab.* )
    forge='gitlab'
    ;;
esac

gh_available=0
glab_available=0
matched_cli='none'
status='unknown-remote'

if command -v gh >/dev/null 2>&1; then
  gh_available=1
fi

if command -v glab >/dev/null 2>&1; then
  glab_available=1
fi

case "$forge" in
  github)
    if [ "$gh_available" -eq 1 ]; then
      matched_cli='gh'
      status='ok'
    else
      status='no-compatible-cli'
    fi
    ;;
  gitlab)
    if [ "$glab_available" -eq 1 ]; then
      matched_cli='glab'
      status='ok'
    else
      status='no-compatible-cli'
    fi
    ;;
esac

printf 'REMOTE_NAME=%s\n' "$remote_name"
printf 'REMOTE_URL=%s\n' "$remote_url"
printf 'REMOTE_HOST=%s\n' "$remote_host"
printf 'FORGE=%s\n' "$forge"
printf 'GH_AVAILABLE=%s\n' "$gh_available"
printf 'GLAB_AVAILABLE=%s\n' "$glab_available"
printf 'MATCHED_CLI=%s\n' "$matched_cli"
printf 'STATUS=%s\n' "$status"
