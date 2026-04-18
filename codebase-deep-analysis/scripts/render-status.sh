#!/usr/bin/env bash
# render-status.sh — regenerate the cluster index in a report's README.md
# from each cluster file's frontmatter `Status:` / `Resolved-in:` fields.
#
# Usage:
#   scripts/render-status.sh <report-dir>
#
# Example:
#   scripts/render-status.sh docs/code-analysis/2026-04-17/
#
# Rewrites the `<!-- cluster-index:start -->` ... `<!-- cluster-index:end -->`
# block inside the report's README.md. If the markers are missing, prints
# the rendered block to stdout and exits 0 so the user can paste it in once.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <report-dir>" >&2
  exit 2
fi

report_dir="${1%/}"
readme="${report_dir}/README.md"
clusters_dir="${report_dir}/clusters"

if [[ ! -d "${clusters_dir}" ]]; then
  echo "no clusters/ under ${report_dir}" >&2
  exit 1
fi

render_block() {
  shopt -s nullglob
  local files=("${clusters_dir}"/*.md)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "- _No clusters rendered._"
    return
  fi

  for f in "${files[@]}"; do
    local base name status resolved_in goal
    base="$(basename "$f" .md)"
    # Extract frontmatter fields (between leading '---' lines).
    status="$(awk '/^---$/{n++; next} n==1 && /^Status:/ {sub(/^Status:[[:space:]]*/,""); print; exit}' "$f")"
    resolved_in="$(awk '/^---$/{n++; next} n==1 && /^Resolved-in:/ {sub(/^Resolved-in:[[:space:]]*/,""); print; exit}' "$f")"
    # Heading line (first "# Cluster ..." line) for display name.
    name="$(awk '/^# Cluster /{print; exit}' "$f" | sed 's/^# //')"
    # Goal line from TL;DR (first "- **Goal:** ..." match).
    goal="$(awk '/^- \*\*Goal:\*\*/{sub(/^- \*\*Goal:\*\*[[:space:]]*/,""); print; exit}' "$f")"

    status="${status:-open}"
    name="${name:-${base}}"
    goal="${goal:-_no goal line found_}"

    local suffix=""
    if [[ "${status}" == "closed" && -n "${resolved_in}" ]]; then
      suffix=" (resolved-in ${resolved_in})"
    elif [[ "${status}" == "resolved-by-dep" && -n "${resolved_in}" ]]; then
      suffix=" (resolved-by-dep ${resolved_in})"
    fi

    printf -- "- [%s](./clusters/%s.md) — %s · **%s**%s\n" \
      "${name}" "${base}" "${goal}" "${status}" "${suffix}"
  done
}

block_start="<!-- cluster-index:start -->"
block_end="<!-- cluster-index:end -->"

rendered="$(render_block)"

if [[ ! -f "${readme}" ]]; then
  echo "${readme} not found — printing rendered block instead:" >&2
  echo "${rendered}"
  exit 0
fi

if ! grep -q "${block_start}" "${readme}" || ! grep -q "${block_end}" "${readme}"; then
  echo "markers missing in ${readme} — paste this block under your cluster list:" >&2
  echo "${block_start}"
  echo "${rendered}"
  echo "${block_end}"
  exit 0
fi

tmp="$(mktemp)"
awk -v start="${block_start}" -v end="${block_end}" -v repl="${rendered}" '
  $0 == start { print; print repl; printing=0; skipping=1; next }
  $0 == end   { skipping=0; print; next }
  !skipping   { print }
' "${readme}" > "${tmp}"

mv "${tmp}" "${readme}"
echo "rewrote cluster index in ${readme}"
