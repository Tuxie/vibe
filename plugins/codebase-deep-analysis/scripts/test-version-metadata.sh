#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

plugin_version="$(
  node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).version)' \
    "$plugin_dir/.claude-plugin/plugin.json"
)"

cda_version="$(tr -d '[:space:]' < "$plugin_dir/skills/codebase-deep-analysis/VERSION")"

if [[ "$cda_version" != "$plugin_version" ]]; then
  printf 'codebase-deep-analysis VERSION mismatch: plugin.json=%s VERSION=%s\n' \
    "$plugin_version" "$cda_version" >&2
  exit 1
fi

printf 'codebase-deep-analysis version metadata ok: %s\n' "$plugin_version"
