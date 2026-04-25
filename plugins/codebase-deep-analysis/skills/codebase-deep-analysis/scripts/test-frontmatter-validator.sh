#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-frontmatter.sh"
renderer="${script_dir}/render-status.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_multi_report() {
  local dir="$1"
  mkdir -p "${dir}/clusters"
  cat > "${dir}/README.md" <<'EOF'
# Report

<!-- cluster-index:start -->
old index
<!-- cluster-index:end -->
EOF
}

write_cluster() {
  local path="$1"
  local status="$2"
  local autonomy="$3"
  local extra="${4:-}"
  cat > "${path}" <<EOF
---
Status: ${status}
Autonomy: ${autonomy}
Resolved-in:
${extra}
---

# Cluster 01 — sample

- **Goal:** keep the report metadata parseable.
EOF
}

assert_passes() {
  local name="$1"
  shift
  "$@" >"${tmp_root}/${name}.out" 2>"${tmp_root}/${name}.err" || {
    cat "${tmp_root}/${name}.err" >&2
    fail "${name} should have passed"
  }
}

assert_fails_with() {
  local name="$1"
  local expected="$2"
  shift 2
  if "$@" >"${tmp_root}/${name}.out" 2>"${tmp_root}/${name}.err"; then
    fail "${name} should have failed"
  fi
  if ! grep -Fq "${expected}" "${tmp_root}/${name}.err"; then
    echo "stderr was:" >&2
    cat "${tmp_root}/${name}.err" >&2
    fail "${name} did not mention ${expected}"
  fi
}

valid_multi="${tmp_root}/valid-multi"
write_multi_report "${valid_multi}"
write_cluster "${valid_multi}/clusters/01-sample.md" "open" "autofix-ready"
assert_passes "valid-multi" bash "${validator}" "${valid_multi}"

missing_status="${tmp_root}/missing-status"
write_multi_report "${missing_status}"
cat > "${missing_status}/clusters/01-sample.md" <<'EOF'
---
Autonomy: autofix-ready
---

# Cluster 01 — sample

- **Goal:** invalid metadata should fail before index rendering.
EOF
assert_fails_with "missing-status" "missing required Status" bash "${validator}" "${missing_status}"
assert_fails_with "render-refuses-missing-status" "frontmatter validation failed" bash "${renderer}" "${missing_status}"

invalid_closed="${tmp_root}/invalid-closed"
write_multi_report "${invalid_closed}"
write_cluster "${invalid_closed}/clusters/01-sample.md" "closed" "autofix-ready"
assert_fails_with "closed-without-resolved-in" "Status closed requires Resolved-in" bash "${validator}" "${invalid_closed}"

duplicate_numbers="${tmp_root}/duplicate-numbers"
write_multi_report "${duplicate_numbers}"
write_cluster "${duplicate_numbers}/clusters/01-one.md" "open" "autofix-ready"
write_cluster "${duplicate_numbers}/clusters/01-two.md" "open" "needs-decision"
assert_fails_with "duplicate-numbers" "duplicate cluster number 01" bash "${validator}" "${duplicate_numbers}"

single="${tmp_root}/single"
cat > "${single}.report" <<'EOF'
placeholder
EOF
mkdir -p "${single}"
cat > "${single}/REPORT.md" <<'EOF'
# Report

<!-- cluster-index:start -->
old index
<!-- cluster-index:end -->

<!-- cluster:01:start -->
<!--
Status: resolved
Autonomy: autofix-ready
Resolved-in:
-->

### Cluster 01 — sample

- **Goal:** invalid single-file status should fail.

<!-- cluster:01:end -->
EOF
assert_fails_with "single-invalid-status" "invalid Status 'resolved'" bash "${validator}" "${single}"

echo "frontmatter validator tests passed"
