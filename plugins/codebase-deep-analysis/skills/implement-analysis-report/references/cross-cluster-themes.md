# Cross-cluster themes (Step 2 detector)

During the primary pass, some frictions hit multiple clusters with the same shape. Bun `mock.module` pollution bites cluster 09 AND cluster 12; tsc cascade errors surface when cluster 13 widens a gate AND cluster 15 moves a test file. Rather than each cluster rediscovering the pattern, iar detects these repeats, logs them to `{report-dir}/.scratch/implement-themes.md`, and Part B surfaces them as first-class observations.

## When the detector runs

After every cluster terminates (closes, partials, or defers) in Step 2, iar inspects the cluster's outcome — subagent output, gate results, any incidental-fixes list, any shape changes — against a known theme-shape catalog below. If the outcome matches a shape, iar appends an entry to `THEMES_LOG` in working memory keyed by shape name.

At the end of Step 2 (before Step 3 showstopper interview), iar filters `THEMES_LOG` for shapes that hit ≥2 clusters. Each qualifying shape becomes a theme entry written to `{report-dir}/.scratch/implement-themes.md`:

```markdown
## Theme: {shape-name}

- **First seen:** cluster {NN-slug} — {1-line observation}
- **Also seen in:** cluster {MM-slug} — {1-line observation}
- **Also seen in:** cluster {PP-slug} — {1-line observation}
- **Pattern:** {2-3 sentence description of what's happening across clusters}
- **Surface:** {which skill should care — cda synthesis / iar preflight / project docs}
```

## Recognized theme shapes

iar detects these shapes by inspecting subagent output + gate output for distinctive signatures. The catalog is deliberately small; add shapes only when they've surfaced across multiple real runs (evidence-driven, not speculative).

### `mock-pollution`

**Signals:**
- Subagent shape-A output mentions "mock.module", "process-global mock", "pollution across test files", "afterAll restore" in its Files-touched notes.
- OR a gate failed with stderr containing `mock.module` AND the failure is in a test file that didn't change in the cluster's scope.
- OR shape-B "cannot implement" reason mentions mock-related leakage.

**Tag:** `mock-pollution`. Surface: project docs (memory bank) — the skill can only flag, not fix.

### `tsc-cascade`

**Signals:**
- Gate `typecheck` failed with >20 errors AND the cluster's Fix was a `tsconfig include` widening or a file move that pulled new types into scope.
- OR shape-A output mentions "tsc errors from adjacent file" or "Locals.ctx / framework type not resolving" in incidental-fixes.

**Tag:** `tsc-cascade`. Surface: cda synthesis (for report-time warning on gate-widening clusters; see `analyst-ground-rules.md` "Gate-widening findings must ballpark…").

### `lint-autofix-cascade`

**Signals:**
- `Incidental fixes` section lists ≥3 unrelated files touched by a linter autofix (biome, eslint --fix, ruff format) that ran after the cluster's primary edits.
- OR a gate failed on lint with pre-existing issues that the cluster's new code amplified (e.g., a new test file brought unused-var warnings to biome's attention).

**Tag:** `lint-autofix-cascade`. Surface: project config (linter severity / autofix boundaries).

### `enshrined-test`

**Signals:**
- Subagent shape-A output's incidental-fixes lists test files deleted or rewritten to remove pre-fix behavior assertions.
- OR shape-B reason mentions "tests enshrine pre-fix behavior".

**Tag:** `enshrined-test`. Surface: cda analyst ground-rules — see the "Enshrined-test check for autofix-ready" rule. Repeated occurrences mean analysts are missing the check; v-next should tighten.

### `drift-surfaced-during-fix`

**Signals:**
- Subagent shape-A output's shape-changes section mentions "Fix: line referenced {symbol} that has been renamed" or "cluster assumed file at {path} but found it at {new path}".
- OR shape-B reason names a renamed/moved symbol.

**Tag:** `drift-surfaced-during-fix`. Surface: cda scout — drift between report generation and fix execution. If it hits ≥2 clusters, the report is stale enough that re-running cda may be cheaper than continuing.

### `pinned-toolchain-mismatch`

**Signals:**
- Gate failed with stderr containing "unknown option" / "cannot find module" / "not found" on a tool invocation AND the project has a `.tool-versions`, `.nvmrc`, `.bun-version`, `rust-toolchain.toml`, or `packageManager` pin.

**Tag:** `pinned-toolchain-mismatch`. Surface: cda analyst ground-rules "Invocation verification for autofix-ready" — repeated occurrences mean analysts are not running the pin check before marking `autofix-ready`.

## Detection algorithm

```
for each cluster in execution order:
  after cluster terminates (close / partial / defer):
    for each shape in CATALOG:
      if shape.signals.match(cluster.subagent_output, cluster.gate_results):
        THEMES_LOG[shape.tag].append({
          cluster_slug: cluster.slug,
          observation: shape.extract_observation(cluster)
        })

before Step 3:
  for tag, entries in THEMES_LOG.items():
    if len(entries) >= 2:
      append theme entry to .scratch/implement-themes.md
```

## Part B integration

`partb-writer.md` reads `{report-dir}/.scratch/implement-themes.md` at Step 5 and includes a **`### Cross-cluster themes that emerged during fix work`** subsection in the session's Part B. Mandatory subsection — but `_none detected_` is acceptable when `implement-themes.md` is empty. Each detected theme appears verbatim from the file.

Themes feed both v-next audiences: the `Surface:` field on each theme points to which skill should absorb the change (cda synthesis, iar preflight, or project docs). Part B's `cda v-next:` and `iar v-next:` bullets may reference the theme by tag for traceability.

## Adding new theme shapes

Add a shape to the catalog only when it has surfaced in ≥2 real-world iar runs. Speculative shapes bloat detection without value. The catalog is a living document in iar's `references/` — each new shape adds a section above with Signals / Tag / Surface fields.

When in doubt about whether a friction is common enough to catalog: don't. A one-off curiosity belongs in Part B's prose, not in the detector.
