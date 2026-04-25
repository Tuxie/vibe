# Report template

Render the synthesized, frozen finding set into **one or more** markdown files under the report directory. Do not mutate the set while rendering.

## Rendering mode

Pick a mode from the Scout's tier + total-finding-count:

| Mode | Trigger | Layout |
|------|---------|--------|
| **Single-file** | `total findings < 15` AND tier ∈ {T1, T2} | one `REPORT.md` + `analysis-analysis.md` + `.scratch/codebase-map.md` + `scripts/` |
| **Compact multi-file** | `15 ≤ total findings < 60` AND tier ∈ {T1, T2} | multi-file layout below, but `by-analyst/` collapses to a single `by-analyst.md` |
| **Full multi-file** | `total findings ≥ 60` OR tier = T3 | full layout below, `by-analyst/` as a directory |

Total-finding-count is the sum across all analysts **after** synthesis §3 right-sizing, not raw. If in doubt between modes, pick the smaller — the user can re-run with a different mode if they wanted more.

For any analyst that was skipped during Step 2, write `_Not applicable — <reason>_` in its by-analyst section/file — do not omit it.

## Directory layout — full multi-file

```
docs/code-analysis/{YYYY-MM-DD | YYYY-MM-DD-HHMMSS}/
├── README.md                    # Index, metadata, token warning, tier + rationale
├── executive-summary.md         # Top clusters per synthesis §7
├── themes.md                    # Cross-cutting patterns (or "none surfaced")
├── analysis-analysis.md         # Retrospective on the skill itself (Step 6); Part A filled now, Part B appended after fix work
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
│   ├── docs.md
│   └── coverage-profiling.md    # Only if Step 3.5 ran (static or dynamic); otherwise omitted
├── checklist.md                 # Full checklist, defects visible
├── meta.md                      # META-1 draft agent-instruction rules (or "none")
├── not-in-scope.md              # What was intentionally skipped, with reasons
├── scripts/
│   ├── render-status.sh         # Copied in at render time; regenerates the cluster index
│   └── validate-frontmatter.sh  # Copied in at render time; render-status calls this before rewriting
└── .scratch/
    └── codebase-map.md          # Scout output, kept for later reference
```

## Directory layout — compact multi-file

Identical to full except `by-analyst/` is a single file:

```
├── by-analyst.md                # One H2 per analyst instead of a directory
```

## Directory layout — single-file

```
docs/code-analysis/{stem}/
├── REPORT.md                    # Everything: metadata, token warning, tier, executive summary, clusters inline, checklist, meta, not-in-scope
├── analysis-analysis.md         # Retrospective (Step 6), same as other modes
├── scripts/
│   ├── render-status.sh         # Still copied; cluster status fields live inside REPORT.md
│   └── validate-frontmatter.sh  # Still copied; validates HTML-comment frontmatter blocks
└── .scratch/
    └── codebase-map.md
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
- Re-dispatch passes: {list targeted senior-tier re-dispatches performed during synthesis, or "none"}
- Right-sizing filter: {N dropped, M fix-rewritten, K below-threshold, P stylistic, Q rule-restatement} — see `not-in-scope.md` for detail.
- Report directory: `{path}`
- Scout map: `.scratch/codebase-map.md`

## Tech stack (excerpt)

{Concise excerpt from the Scout map — tech stack block and entry points. One paragraph plus a short list is enough; link `.scratch/codebase-map.md` for the full map.}

## Index

- [Executive summary](./executive-summary.md) — top {N} clusters
- [Themes](./themes.md) — cross-cutting patterns
- **Clusters** (ordered by recommended fix sequence; regenerate with `./scripts/render-status.sh .` from this report's directory after flipping any cluster's `Status:`; this validates frontmatter before rewriting):

<!-- cluster-index:start -->
- [Cluster 01 — {slug}](./clusters/01-{slug}.md) — {one-line goal} · **open** · autofix-ready
- [Cluster 02 — {slug}](./clusters/02-{slug}.md) — {one-line goal} · **open** · needs-decision
- …
<!-- cluster-index:end -->
- **By analyst** (for traceability, not for reading end-to-end):
  - Full multi-file mode: [backend](./by-analyst/backend.md) · [frontend](./by-analyst/frontend.md) · [database](./by-analyst/database.md) · [tests](./by-analyst/tests.md) · [security](./by-analyst/security.md) · [tooling](./by-analyst/tooling.md) · [docs](./by-analyst/docs.md)
  - Compact multi-file mode: [by-analyst](./by-analyst.md) (single file; one H2 per analyst)
- [Checklist](./checklist.md)
- [META-1 draft rules](./meta.md)
- [Out of scope](./not-in-scope.md)

## How to use this report

1. Read the executive summary.
2. Pick one cluster. Open its file. Start a brainstorming session against that cluster alone — do not try to bundle clusters.
3. When a cluster's status changes, flip `Status:` inside the cluster file and set `Resolved-in:` to the merging commit SHA (or form `SHA (partial — <blocker>)` for `partial`). Then from this report's directory run `./scripts/render-status.sh .` to validate the frontmatter and regenerate the index block above. **Do not edit the index by hand** — it will drift. The scripts were copied into this report at render time, so you can run them without the skill repo on disk.

## Commit conventions

Every commit resolving a cluster (fully or partially) follows these rules:

1. **Subject line names cluster slug and date:** e.g., `fix(cluster 03-perf-hotpath, 2026-04-17): …`. This lets `git log --grep='cluster 03'` navigate the report later, and lets `Resolved-in:` stay machine-findable.
2. **Incidental fixes section.** If the fix had to touch code outside the cluster's named scope to pass a verification gate (typecheck, lint, existing tests), add an `Incidental fixes` section listing each extra file with a one-line reason. See `synthesis.md` §12 for when this is legitimate.
3. **Do not name `Depends-on:` in the commit message** — that relationship is carried by the cluster file's frontmatter, not the git log. If the fix also resolved a finding from another cluster (via `Depends-on:` chain), flip that downstream cluster to `Status: resolved-by-dep` separately; synthesis §11 covers the semantics.
4. **`informally-unblocks:` edges are not named in commits either.** They are soft ordering hints, not promises.

Per-cluster files only add commit-message guidance when there's cluster-specific context (expected scope expansion, a `Depends-on:` chain to traverse, a known-hairy `Incidental fixes` set).

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

Each cluster file is a living artifact: its `Status:` field is the source of truth for the README index. When a cluster's status changes, flip it here and regenerate the index (`./scripts/render-status.sh .` from the report directory). The renderer validates frontmatter first and refuses to rewrite the index on malformed metadata. Do not edit the README index by hand.

```markdown
---
Status: open
Autonomy: autofix-ready | needs-decision | needs-spec
Resolved-in:
Depends-on:
informally-unblocks:
Pre-conditions:
attribution:
Commit-guidance:
model-hint:
---

# Cluster {NN} — {slug}

## TL;DR

- **Goal:** {one sentence}
- **Impact:** {one line — what breaks / improves when this lands}
- **Size:** {Small (<2h) | Medium (half-day) | Large (full day+)}
- **Depends on:** {none | cluster NN-slug}
- **Severity:** {highest in cluster}
- **Autonomy (cluster level):** {autofix-ready | needs-decision | needs-spec}

## Header

> Session size: {Small | Medium | Large} · Analysts: {list} · Depends on: {none | cluster NN-slug} · Autonomy: {…}

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

{2–3 sentences sketching how a brainstorming session might structure the work. This is the one place in the report where rendered output adds guidance beyond synthesis — keep it operational, not philosophical. If the cluster is straight mechanical fixes, say so and recommend subagent dispatch instead of brainstorming. For mechanical clusters with >3 findings, walk one concrete implementation sketch for the most non-trivial finding — see `synthesis.md` §6 "Mechanical-cluster sanity check".}

```

**No optional `## Commit-message guidance` H2.** The canonical commit rules live in README's "Commit conventions" section. Per-cluster commit notes (expected `Incidental fixes`, a `Depends-on:` chain to traverse, a known-hairy scope-expansion risk) go in the frontmatter `Commit-guidance:` field as a single line. Example:

```
Commit-guidance: expect an `Incidental fixes` section — the biome autofix sweep after this cluster's rewrites touches 4 unrelated files
```

An empty `Commit-guidance:` field is the norm; do not pad it for every cluster.

### Frontmatter field reference

| Field | Required? | Purpose |
|-------|-----------|---------|
| `Status:` | required | lifecycle state; see table below |
| `Autonomy:` | required | cluster-level autonomy; the weakest constituent finding's autonomy (`needs-spec` > `needs-decision` > `autofix-ready`). Surfaced in README index so the fix coordinator can batch maintainer interviews. |
| `Resolved-in:` | optional | commit SHA or tag that resolved the cluster. Form for `partial`: `SHA (partial — <blocker>)`. Form for `resolved-by-dep`: commit SHA of the upstream cluster that resolved this one. |
| `Depends-on:` | optional | hard edge: this cluster's fix requires another cluster's structure first. Format: `NN-slug` (no `cluster` prefix, no hash). One slug per line if multiple. Rendered in README index as `→ NN` adjacency marker. |
| `informally-unblocks:` | optional | soft edge: this cluster's work becomes easier after another lands, but is not required. Format: `NN-slug` (one per line). Rendered in README index as `⇢ NN`. Not an ordering constraint — fix order is still driven by severity and `Depends-on:`. |
| `Pre-conditions:` | optional | prerequisites this cluster's fix needs in place to land cleanly. Populated automatically by synthesis §5 "Pre-conditions inference" when the cluster flips a gate (coverage threshold, lint rule, type check) and in-scope files currently fail that gate. Format: bulleted list, each `- <file-or-cluster-ref>: <required state>`. |
| `attribution:` | optional | fuzz-gap convention. When a fuzz-gap cluster's recommended fix catches a bug whose scope belongs to a different cluster, the bug lands in the fuzz cluster's commit but `attribution:` names the originating cluster: `attribution: 04-input-validation (caught-by: 15-fuzz-gaps)`. Do not re-file the bug under the origin cluster. |
| `Commit-guidance:` | optional | single-line prose with cluster-specific commit notes — expected `Incidental fixes` scope, a `Depends-on:` chain to traverse, a known scope-expansion risk. Leave empty when there are no cluster-specific notes; the canonical commit rules live in the README's "Commit conventions" section. Do not restate canonical rules here. |
| `model-hint:` | optional | `junior` \| `standard` \| `senior` — synthesis populates per cluster (see `synthesis.md` §6). Default `standard`. `iar` reads this when dispatching per-cluster subagents. Absent = standard fallback. |

Minimal frontmatter is valid when optional fields are empty. A typical cluster may carry only:

```
Status: open
Autonomy: autofix-ready
model-hint: standard
```

Do not add empty optional fields solely for visual symmetry.

### Cluster `Status` lifecycle

| Value | Meaning |
|-------|---------|
| `open` | Nothing started. Default on render. |
| `in-progress` | A fix session is underway; commit(s) may exist on a branch but not merged. |
| `closed` | Fix fully merged. `Resolved-in:` is a commit SHA or tag. |
| `partial` | One or more findings in the cluster landed; remainder blocked on a named external dependency (toolchain bump, upstream bug, vendor release). `Resolved-in:` takes form `SHA (partial — <blocker>)`. The cluster file body must name which findings closed and which are blocked. |
| `deferred` | Cluster intentionally punted whole. Populate a `Deferred-reason:` inline field under the `---` block and cross-link to the deferral tracking location. Acceptable locations: an issue, a file under `docs/ideas/<slug>.md`, a skill checkbox. See synthesis §8 / §11 + SKILL.md "Deferring shaped work". |
| `resolved-by-dep` | Cluster is fixed as a side-effect of another cluster's merge (per synthesis §11). Set `Resolved-in:` to the upstream commit and add `Resolving-cluster:` to name the upstream cluster slug. |

`Status:`, `Autonomy:`, `Resolved-in:`, and the edge fields (`Depends-on:`, `informally-unblocks:`, `attribution:`) are the fields the user edits by hand after the report lands. Everything else in the cluster file is frozen synthesis output.

---

## `by-analyst/{agent}.md` template (full multi-file mode)

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

## `by-analyst.md` template (compact multi-file mode)

Single file; one H2 per analyst. Same sub-sections per analyst as the full-mode file. Skipped analysts get a one-line `_Not applicable — {reason}._` under their H2, not a full per-file stub.

```markdown
# By-analyst dumps

> Preserved for traceability. For fix work, use the clusters under `./clusters/` — they cross-cut these per-analyst sections.

## Backend Analyst

### Summary
…
### Findings
…
### Checklist (owned items)
…

## Frontend Analyst
…

## Database Analyst

_Not applicable — no database surface (Scout flag `database: absent`)._

## Tests Analyst
…
```

Mode is chosen per the "Rendering mode" table near the top of this file.

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
# Suggested agent-instruction additions (META-1)

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
- Rule-restatement (already in project instructions / docs): **{N}**

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

## Single-file `REPORT.md` template (single-file mode)

One file holds everything. Cluster frontmatter still exists, but lives inside the document as HTML comments around each cluster's Status block so `render-status.sh` can still read and rewrite them. Section order:

```markdown
# Codebase Analysis — {YYYY-MM-DD or YYYY-MM-DD-HHMMSS}

> **Heavy token usage.** Before kicking off a brainstorming session from any cluster here, confirm that weekly quota has spare headroom.

## Project tier: **{T1|T2|T3}**

{rationale}

## Run metadata

{same block as full-mode README, with a note: "Rendering mode: single-file (N findings total, tier T{1|2})"}

## Commit conventions

{same canonical block as full-mode README "Commit conventions"}

## Index

<!-- cluster-index:start -->
- [Cluster 01 — {slug}](#cluster-01-{slug}) — {one-line goal} · **open** · autofix-ready
- …
<!-- cluster-index:end -->

## Executive summary

{body — inline, not a separate file}

## Themes

{body}

## Clusters

<!-- cluster:01:start -->
<!--
Status: open
Autonomy: autofix-ready
Resolved-in:
Depends-on:
informally-unblocks:
Pre-conditions:
attribution:
-->

### Cluster 01 — {slug}

{cluster body: TL;DR, Files touched, Severity & autonomy, Findings, Suggested session approach}

<!-- cluster:01:end -->

<!-- cluster:02:start -->
…
<!-- cluster:02:end -->

## Checklist

{per-category sections, same as multi-mode `checklist.md`}

## META-1 draft rules

{body}

## Out of scope

{body}

## By-analyst dumps

{one H3 per analyst, same content as compact-mode `by-analyst.md`}
```

`render-status.sh` reads the `<!-- cluster:NN:start -->` / `<!-- cluster:NN:end -->` block and the commented-frontmatter inside it, same as reading `clusters/NN-slug.md` in multi-file mode. It validates these blocks with `validate-frontmatter.sh` before rewriting the index. The user edits the `Status:`, `Autonomy:`, `Resolved-in:` lines inside the HTML comment; the rest of the cluster body is frozen.

{IF `Pre-release surface: Recommend yes` in scout output, append the Pre-release verification checklist section per the README template's conditional block.}

## Rendering notes

- **Ordering inside clusters and by-analyst sections:** Severity desc → Confidence desc → `file:line`. Use synthesis output's order; do not re-sort.
- **Empty sections:** under a section header, write `_No findings._` only if the analyst ran and reported zero findings. Write `_Not applicable — <reason>_` only if the analyst was skipped.
- **Secret hygiene:** when rendering findings, double-check no body contains a quoted credential, API key, hash, or private key. If synthesis missed one, strip at render time and note `[redacted]`.
- **Line-number drift:** if Run metadata says `dirty`, per-finding `Location:` lines render as-is; the README warning covers the reader.
- **No editorializing:** rendering adds zero commentary or recommendations beyond what synthesis produced, with the single exception of the `Suggested session approach` block in each cluster file (which is bounded to 2–3 operational sentences).
- **Cross-references:** every finding that lives in a cluster gets a `→ see cluster NN-{slug}` pointer in its `by-analyst` section. Clusters do not need a pointer back to `by-analyst` — the cluster is authoritative.
- **Copy status scripts in at render time.** All three modes copy `render-status.sh` and `validate-frontmatter.sh` so the report directory is self-contained and the fix coordinator can run `./scripts/render-status.sh .` from inside the report dir.
