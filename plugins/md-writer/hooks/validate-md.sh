#!/bin/bash
# PostToolUse hook: validate markdown files with markdownlint
# Uses project .markdownlint.json if present, otherwise falls back to plugin default

file_path=$(cat | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$file_path" ] || [[ "$file_path" != *.md ]]; then
  exit 0
fi

if ! command -v npx &> /dev/null; then
  exit 0
fi

# Use CLAUDE_PLUGIN_ROOT env var (set by Claude Code for plugin hooks)
# Fall back to dirname resolution for direct invocation / testing
plugin_dir="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
default_config="$plugin_dir/.markdownlint.json"

# Walk up from the file's directory looking for a user config
config_names=(".markdownlint.json" ".markdownlint.jsonc" ".markdownlint.yaml" ".markdownlint.yml")
search_dir="$(dirname "$file_path")"
user_config=""

while [ "$search_dir" != "/" ]; do
  for name in "${config_names[@]}"; do
    if [ -f "$search_dir/$name" ]; then
      user_config="$search_dir/$name"
      break 2
    fi
  done
  search_dir="$(dirname "$search_dir")"
done

config="${user_config:-$default_config}"

# cd into plugin dir so npx resolves node_modules/markdownlint-cli2
# Use absolute file path and config path since we're changing directory
result=$(cd "$plugin_dir" && npx markdownlint-cli2 --config "$config" "$file_path" 2>&1)

if [ $? -ne 0 ]; then
  echo "markdownlint violations found:" >&2
  echo "$result" >&2
  exit 2
fi

exit 0
