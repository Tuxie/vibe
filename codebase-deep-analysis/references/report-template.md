# Report template

Render the synthesized, frozen finding set into a **directory** of files, not a single file. Do not mutate the set while rendering. For any analyst that was skipped during Step 2, write `_Not applicable — <reason>_` in its by-analyst file — do not omit the file.

## Directory layout

```
docs/code-analysis/{YYYY-MM-DD | YYYY-MM-DD-HHMMSS}/
├── README.md                    # Index, metadata, token warning, tier + rationale
├── executive-summary.md         # Top clusters per synthesis §7
├── themes.md                    # Cross-cutting patterns (or "none surfaced")
├── clusters/
│   ├── 01-{slug}.md            # Session-sized fix bundles, ordered by priority
│   ├── 02-{slug}.md
│   └── ...
├── by-analyst/                  # Preserves analyst-native dumps for traceability
│   ├── backend.md
│   ├── frontend.md
│   ├── database.md
│   ├── tests.md
│   ├── security.md
│   ├── tooling.md
│   └── docs.md
├── checklist.md                 # Full checklist, defects visible
├── meta.md                      # META-1 draft CLAUDE.md rules (or "none")
├── not-in-scope.md              # What was intentionally skipped, with reasons
└── .scratch/
    └── codebase-map.md          # Scout output, kept for later reference
```

The folder slug is the date (or date + time on collision). `clusters/` numbering reflects recommended fix order.

---

## `README.md` template

```markdown
# Codebase Analysis — {YYYY-MM-DD or YYYY-MM-DD-HHMMSS}

> **Heavy token usage.** Before kicking off a brainstorming session from any cluster here, confirm that weekly quota has spare headroom — follow-up sessions can easily spend as much as this analysis did.

## Project tier: **{T1|T2|T3}**

{One-paragraph rationale — what evidence drove the tier call, quoted from the Scout map. If you disagree with the tier on reading this report, re-run the skill with the Scout overridden; every finding below was filtered through this tier.}

## Run metadata

- Repo: `{repo root path}`
- Git head: `{short sha}` on branch `{branch}`
- Working tree at analysis time: **clean** | **dirty** — _if dirty, `file:line` references below may shift after subsequent commits, reverts, or rebases._
- Analysts dispatched: {comma-separated list}
- Analysts skipped: {comma-separated list with one-line reason each, or "none"}
- Scope overrides: {list any per-agent scope-glob overrides that differed from `agent-roster.md` defaults, or "none"}
- Re-dispatch passes: {list targeted Opus re-dispatches performed during synthesis, or "none"}
- Right-sizing filter: {N dropped, M fix-rewritten, K below-threshold, P stylistic, Q rule-restatement} — see `not-in-scope.md` for detail.
- Report directory: `{path}`
- Scout map: `.scratch/codebase-map.md`

## Tech stack (excerpt)

{Concise excerpt from the Scout map — tech stack block and entry points. One paragraph plus a short list is enough; link `.scratch/codebase-map.md` for the full map.}

## Index

- [Executive summary](./executive-summary.md) — top {N} clusters
- [Themes](./themes.md) — cross-cutting patterns
- **Clusters** (ordered by recommended fix sequence; regenerate with `scripts/render-status.sh <report-dir>` after flipping any cluster's `Status:`):

<!-- cluster-index:start -->
- [Cluster 01 — {slug}](./clusters/01-{slug}.md) — {one-line goal} · **open**
- [Cluster 02 — {slug}](./clusters/02-{slug}.md) — {one-line goal} · **open**
- …
<!-- cluster-index:end -->
- **By analyst** (for traceability, not for reading end-to-end):
  - [backend](./by-analyst/backend.md) · [frontend](./by-analyst/frontend.md) · [database](./by-analyst/database.md) · [tests](./by-analyst/tests.md) · [security](./by-analyst/security.md) · [tooling](./by-analyst/tooling.md) · [docs](./by-analyst/docs.md)
- [Checklist](./checklist.md)
- [META-1 draft rules](./meta.md)
- [Out of scope](./not-in-scope.md)

## How to use this report

1. Read the executive summary.
2. Pick one cluster. Open its file. Start a brainstorming session against that cluster alone — do not try to bundle clusters.
3. When a cluster is resolved, flip `Status:` inside the cluster file and set `Resolved-in:` to the merging commit SHA. Then run `scripts/render-status.sh` (see repo root of this report) to regenerate the index block above. **Do not edit the index by hand** — it will drift.

{IF `Pre-release surface: Recommend yes` in scout output, render this block:}

## Pre-release verification checklist

This repo has both CI config ({list}) and a local CI-equivalent runner ({list}). Before tagging a release:

- [ ] Run the local runner against the release workflow on a throwaway branch. Catches workflow-level typos before they fail the real push.
- [ ] Verify the commit(s) resolving closed clusters (see index above) are all on the release branch.
- [ ] Confirm no cluster still `in-progress` is a release blocker.
- [ ] Confirm `not-in-scope.md` "Deferred this run" entries are either still deferred-on-purpose or have tracking tickets.

{ENDIF}
```

---

## `executive-summary.md` template

```markdown
# Executive summary

Top {1–5} clusters selected per `synthesis.md` §7.

{For each cluster:}

## {NN} — {cluster slug}

- **Goal:** {one sentence}
- **Files touched:** {N} · **Severity spread:** {Critical: N, High: N, Medium: N, Low: N}
- **Autonomy mix:** {autofix-ready: N, needs-decision: N, needs-spec: N}
- **Est. session size:** {Small | Medium | Large}
- **Why it's in the summary:** {one sentence tying to §7 criteria — e.g., "Critical SEC finding in auth middleware, spans 3 files"}
- **Read:** [cluster file](./clusters/{NN-slug}.md)

{If fewer than 5 clusters qualify, list only those that qualify. Do not pad. If zero qualify, write `_No clusters met Executive Summary thresholds this run._` and let the user decide whether that's a healthy repo or a weak analysis.}
```

---

## `clusters/{NN-slug}.md` template

Each cluster file is a living artifact: its `Status:` field is the source of truth for the README index. When a cluster closes, flip `Status:` here and regenerate the index (see `scripts/render-status.sh`). Do not edit the README index by hand.

```markdown
---
Status: open
Resolved-in:
---

# Cluster {NN} — {slug}

## TL;DR

- **Goal:** {one sentence}
- **Impact:** {one line — what breaks / improves when this lands}
- **Size:** {Small (<2h) | Medium (half-day) | Large (full day+)}
- **Depends on:** {none | cluster NN}
- **Severity:** {highest in cluster}

## Header

> Session size: {Small | Medium | Large} · Analysts: {list} · Depends on: {none | cluster NN}

## Files touched

- `path/one.ts` (3 findings)
- `path/two.ts` (1 finding)
- …

## Severity & autonomy

- Critical: {N} · High: {N} · Medium: {N} · Low: {N}
- autofix-ready: {N} · needs-decision: {N} · needs-spec: {N}

## Findings

{Full finding bodies, ordered Severity desc → Confidence desc → file:line. Preserve `Raised by:`, `Fix:`, `Autonomy:`, `Notes:`, `Depends-on:` verbatim from synthesis. Include the `Cluster hint:` line from the source finding for traceability.}

- **{Title}** — {description}
  - Location: `path/to/file:LINE`
  - Severity: {…} · Confidence: {…} · Effort: {…} · Autonomy: {…}
  - Cluster hint: `{original-hint}`
  - Depends-on: {optional, e.g., `cluster 01-swap-console-log`}
  - Fix: {verified replacement if present}
  - Raised by: {agents}
  - Notes: {optional}

## Suggested session approach

{2–3 sentences sketching how a brainstorming session might structure the work. This is the one place in the report where rendered output adds guidance beyond synthesis — keep it operational, not philosophical. If the cluster is straight mechanical fixes, say so and recommend subagent dispatch instead of brainstorming.}

## Commit-message guidance

When the fix for this cluster lands, the commit message (or PR body) should:

1. Name the cluster slug and date on the first line — e.g., `fix(cluster 03-perf-hotpath, 2026-04-17): …`. This is what lets `Resolved-in:` stay machine-findable.
2. If the fix touched code outside the cluster to unblock a verification gate, add an **`Incidental fixes`** section listing each extra file with a one-line reason. See `synthesis.md` §12 for when this is legitimate.
3. If the fix also resolved a finding from another cluster (via `Depends-on:` chain), name that cluster — synthesis §11 uses this to update `Status: resolved-by-dep` downstream.
```

### Cluster `Status` lifecycle

| Value | Meaning |
|-------|---------|
| `open` | Nothing started. Default on render. |
| `in-progress` | A fix session is underway; commit(s) may exist on a branch but not merged. |
| `closed` | Fix merged. `Resolved-in:` must be set to a commit SHA (or tag) that resolved the cluster. |
| `deferred` | Cluster intentionally punted. Populate a `Deferred-reason:` inline field under the `---` block and cross-link to where the deferral is tracked (issue, follow-up doc, skill checkbox). See synthesis §8 / §11. |
| `resolved-by-dep` | Cluster is fixed as a side-effect of another cluster's merge (per synthesis §11). Set `Resolved-in:` to the upstream commit and add `Resolving-cluster:` to name the upstream cluster slug. |

`Status:` is the **only** field the user edits by hand after the report lands. Everything else in the cluster file is frozen synthesis output.

---

## `by-analyst/{agent}.md` template

```markdown
# {Agent name} — analyst-native output

> Preserved for traceability. For fix work, use the clusters under `../clusters/` — they cross-cut these per-analyst sections.

## Summary

{2–3 sentences from the analyst, verbatim.}

## Findings

{Full analyst finding list after dedup/right-sizing, ordered Severity desc → Confidence desc. Note: findings appearing in clusters have a `→ see cluster NN-{slug}` pointer appended.}

## Checklist (owned items)

{Per-item lines as emitted, with any defect suffixes from synthesis §8.}
```

If the analyst was skipped entirely, the file contains only:

```markdown
# {Agent name}

_Not applicable — {reason from Step 2 scope resolution}._
```

---

## `themes.md` template

```markdown
# Themes

Cross-cutting patterns surfaced per `synthesis.md` §5. Each theme links to the clusters that address it.

{For each theme:}

## {Theme name}

- **Pattern:** {description}
- **Occurrences:** {N} across {M} files.
- **Sample locations:** `file.ts:10`, `other.ts:42`, `third.ts:7`
- **Severity:** {highest occurrence}
- **Raised by:** {agents}
- **Fix sketch:** {only if fixes converge; otherwise omit}
- **Addressed in clusters:** {NN-slug, MM-slug, …}

{If no themes surfaced: `_No cross-cutting themes surfaced this run._`}
```

---

## `checklist.md` template

```markdown
# Checklist

Rendered per-item in ID order, grouped by category (EFF, PERF, QUAL, …). Multi-owner items show one line per owning scope (see `synthesis.md` §4). Defect-demoted entries appear verbatim with their `— defect: …` suffix so the weakest parts of the analysis stay visible.

## EFF

- `EFF-1 [x] src/lib/server/enrichment.ts:412 — see cluster 03 (perf-hotpath)`
- `EFF-2 [x] clean — sampled all ~40 handlers under src/routes/api`
- `EFF-3 [x] src/old/* — see cluster 07 (dead-code-sweep)`

## PERF

- `PERF-1 [-] N/A — below profile threshold (project=T1)`
- …

{... continue for every category in checklist.md, in ID order ...}
```

---

## `meta.md` template

```markdown
# Suggested CLAUDE.md additions (META-1)

Drafts per `synthesis.md` §9. Each rule would have prevented ≥3 recurrences of a finding.

- **{Draft rule}** — prevents: {IDs / anchors}. Rationale: {one sentence}.
- …

{If none: `_No recurring finding shapes surfaced this run; no new rule drafted._`}
```

---

## `not-in-scope.md` template

```markdown
# Out of scope / filtered out

This file records what the analysis intentionally did **not** produce, so the user can see the shape of what was excluded rather than mistaking silence for clean.

## Analysts skipped

- {Analyst}: {reason from Step 2}
- …

## Findings filtered during right-sizing (synthesis §3)

- Tier-mismatch, dropped: **{N}** — e.g., "{short example}"
- Tier-mismatch, fix rewritten to fit tier: **{N}**
- Below profile threshold (project=T{N}): **{N}**
- Stylistic restatement: **{N}**
- Rule-restatement (already in CLAUDE.md / docs): **{N}**

## Deferred this run

Findings the analysts raised as real but intentionally punted this run (checklist state `[~] deferred`). Each entry names its tracking location so the next analysis or the next release checklist can pick up where we left off.

- {ID or finding title} — `{file:line}` — reason: {one line} — tracking: {cluster NN | issue URL | file path}
- …

{If none: `_No items deferred this run._`}

## Structural exclusions (never examined statically)

- Runtime profiling / load testing
- Production telemetry and actual error rates
- External service reliability
- Anything requiring credential access or network calls

## Tier-rule skipped checklist items

- {ID}: {reason — usually "min-tier > project tier, no counter-evidence"}
- …
```

---

## Rendering notes

- **Ordering inside clusters and by-analyst sections:** Severity desc → Confidence desc → `file:line`. Use synthesis output's order; do not re-sort.
- **Empty sections:** under a section header, write `_No findings._` only if the analyst ran and reported zero findings. Write `_Not applicable — <reason>_` only if the analyst was skipped.
- **Secret hygiene:** when rendering findings, double-check no body contains a quoted credential, API key, hash, or private key. If synthesis missed one, strip at render time and note `[redacted]`.
- **Line-number drift:** if Run metadata says `dirty`, per-finding `Location:` lines render as-is; the README warning covers the reader.
- **No editorializing:** rendering adds zero commentary or recommendations beyond what synthesis produced, with the single exception of the `Suggested session approach` block in each cluster file (which is bounded to 2–3 operational sentences).
- **Cross-references:** every finding that lives in a cluster gets a `→ see cluster NN-{slug}` pointer in its `by-analyst` copy. Clusters do not need a pointer back to `by-analyst` — the cluster is authoritative.
