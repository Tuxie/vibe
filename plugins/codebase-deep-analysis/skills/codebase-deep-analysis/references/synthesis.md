# Synthesis & dedup

Run this after every dispatched analyst has returned. Do not start writing the report until every step below has run.

## 1. Collect

Put each agent's `Findings` block into an indexed list. Tag every entry with the raising agent's name. Keep the original text verbatim — no rewrites yet.

## 1b. Analyst output health check

Before dedup, assess each analyst's output for signs of shallow analysis. Flag but do not auto-reject — the flags feed into §10 (targeted re-dispatch) and into the Run metadata so the user can see where coverage was weakest.

| Signal | Threshold | Action |
|--------|-----------|--------|
| **Suspiciously thin output** | <3 findings for an analyst whose scope covers >20 files | Flag: `{AGENT_NAME}: {N} findings across {M}-file scope — possible under-analysis`. Candidate for §10 re-dispatch. |
| **High clean-sweep ratio** | >60% of owned checklist items marked `clean` AND <5 findings | Flag: `{AGENT_NAME}: {N}% clean ratio with {M} findings — verify sampling depth`. Review the `clean` sampling statements for adequacy (see agent-prompt-template sampling requirement). |
| **Zero source-drops on non-trivial scope** | `Dropped at source: 0` on a scope with >30 files | Flag: `{AGENT_NAME}: zero drops on {M}-file scope — either unusually clean code or analyst did not look deeply enough`. Not a defect by itself, but note it. |
| **High source-drop ratio** | `Dropped at source` count exceeds reported findings count | Flag: `{AGENT_NAME}: dropped more findings ({N}) than reported ({M}) — review drop reasons for over-filtering`. Walk the drop breakdown; if >50% are "borderline", the analyst may have been too aggressive with the escape hatch. |
| **Confidence clustering at Plausible** | >50% of findings marked `Plausible` when source is static-readable | Flag: `{AGENT_NAME}: {N}% Plausible — analyst may have avoided code-level verification`. |
| **Autonomy clustering at needs-decision** | >50% of findings marked `needs-decision` | Flag: `{AGENT_NAME}: {N}% needs-decision — verify that alternatives genuinely exist for each`. |

Record all flags under Run metadata as `Analyst health: {flags}`. If no flags fire, record `Analyst health: all outputs within expected ranges`.

A single flag is a data point. Two or more flags on the same analyst is a strong signal of under-analysis and should trigger §10 re-dispatch on that analyst's scope.

## 2. Dedup by anchor

Primary anchor: exact `file:line`. Secondary anchor: same `file` + same topic (e.g., "uses `console.log` instead of project logger").

Merge entries that share an anchor into a single finding. The merged entry lists all raising agents in a `Raised by:` line.

When **severities differ** across agents for the same finding:

- Record the spread explicitly: `Severity: High (Backend), Medium (Frontend) — resolved to High`.
- Take the highest; do not average.

When **confidences differ**:

- Take the highest.
- If one agent says Verified and another Speculative, keep the Verified agent's `Fix:` line (if present). Do not invent a fix from the Speculative entry.

When **fixes differ**:

- If both are Verified and conflict, list both as alternatives. Do not silently pick one.

When **autonomy tags differ**:

- Take the most conservative (needs-spec > needs-decision > autofix-ready). A fix is only autofix-ready if every agent raising it agrees.

When a finding carries `Depends-on: cluster {slug}` (or `Depends-on: finding {anchor}`):

- Keep the dependency edge in the merged entry.
- During cluster assembly (§6), place the dependent finding in the downstream cluster and add `Depends on cluster(s): {slug}` to that cluster's metadata.
- If the dependency has already landed in the user's workflow between analysis and fix (e.g., the earlier cluster's merge also fixed this finding incidentally), mark the finding `Status: resolved-by-dep` during re-synthesis rather than re-flagging it. See §11 for when to re-synthesize.

## 3. Right-sizing filter (CRITICAL for report quality)

Walk every merged finding from §2 against the Scout's project tier. The goal is to strip inactionable noise before anything else happens.

Drop or downgrade a finding when **any** of these hold:

- **Tier mismatch.** The finding's canonical fix requires infrastructure, team structure, or process the project does not have (e.g., "add distributed tracing" on a T1 repo, "implement circuit breaker" on a T1 CLI tool, "introduce CODEOWNERS review gate" on a solo repo).
  - If the underlying problem is real but only the heavy fix is inappropriate: **keep the finding, rewrite its `Fix:` line** into something tier-appropriate (or drop the `Fix:` line and downgrade to `needs-decision` if no light fix exists). Note the rewrite under `Notes:` as `Tier-rewrite: original fix was {X}`.
  - If the problem itself only matters at a higher tier (e.g., SEO metadata on an internal hobby tool): **drop outright** and record it in the "Filtered out" tally below.
- **Below profile threshold but emitted anyway.** An analyst emitted a finding for an item whose min-tier exceeds the project tier, and the repo shows no counter-evidence of intent. Drop, record in Filtered out.
- **Stylistic restatement.** Finding reduces to "this doesn't match my preference" with no concrete failure mode and no linter/formatter backing. **Narrow definition:** a stylistic restatement is a pure formatting/taste preference (tabs vs spaces, brace placement, trailing commas). Structural problems like duplicated code, missing abstractions, inconsistent naming conventions, or architectural smells are **not** stylistic even if they involve "style" in the colloquial sense. When in doubt, keep the finding.
- **Canonical-rule re-report.** Finding restates something `CLAUDE.md` / `AGENTS.md` / `README.md` already documents as an intentional decision.

**Record filter activity explicitly.** Produce a `Filtered out` tally for the Run metadata:

```
Filtered out during right-sizing: {N} findings.
Breakdown: {M} tier-mismatch (dropped), {K} tier-mismatch (fix rewritten), {L} below-threshold, {P} stylistic, {Q} rule-restatement, {D} deferred.
```

`deferred` counts findings with a `[~] deferred` checklist line or equivalent finding-level deferral — they are not dropped, they land in `not-in-scope.md` under "Deferred this run" with their tracking location.

If this tally is near zero on a T1 project, the analysts under-filtered — flag it in the report's Notes section so the user can recalibrate the skill for next run.

## 4. Resolve ownership collisions

When two agents own the same checklist ID for their respective scopes (e.g., Backend and Frontend both own `QUAL-1`), the report shows **both** checklist lines with subscope noted:

```
QUAL-1 [x] (backend) src/lib/server/enrichment.ts:120 — see finding #4
QUAL-1 [x] (frontend) clean — sampled all components under src/lib/components
```

The findings themselves dedup by anchor per §2; ownership collision is a checklist-display concern, not a findings concern.

## 5. Promote cross-cutting themes

If the same pattern appears in **≥3 distinct files across ≥2 agents** after right-sizing, create a theme entry:

```
- **Theme: {name}** — {pattern description}. {N} occurrences across {M} files.
  - Sample: file.ts:10, other.ts:42, third.ts:7
  - Severity: {highest occurrence severity}
  - Fix sketch: {only if the fix converges across occurrences; otherwise omit}
  - Raised by: {agents}
```

Theme entries live under a dedicated Themes section and are eligible for the Executive Summary.

## 6. Cluster findings into fix sessions (hybrid)

Each fix-session cluster becomes its own report file (`clusters/NN-{slug}.md`). Goal: each cluster is a self-contained chunk of work a brainstorming session can address without constant context-switching.

**Hybrid procedure:**

1. **Seed from `Cluster hint:` labels.** Group all findings sharing a hint into a candidate cluster.
2. **Reshape.** Walk candidates and adjust:
   - **Merge** two candidates if their file sets overlap substantially (≥50% of the smaller set) or if they describe the same subsystem boundary.
   - **Split** any candidate exceeding the soft cap below.
   - **Rehome** stragglers (findings with unique hints) into the nearest cluster that shares a file or subsystem. If no fit exists, place them in a `misc-{severity}.md` cluster at the end.
3. **Apply soft cap.** Target 5–10 findings per cluster. Split when >12. A cluster of 15+ is almost always two clusters wearing a trench coat.
4. **Apply floor rule.** Merge singleton clusters (1 finding) into the nearest topical cluster by default. A singleton survives only when **all** hold: (a) its fix is genuinely a self-contained session, (b) no other cluster shares its file or subsystem, AND (c) no other cluster shares its decision axis (autofix vs. needs-decision vs. needs-spec). "Topically isolated but small" is not enough — merge upward to the weakest adjacent cluster rather than ship a singleton. Expect ≤1 singleton per 10 clusters after synthesis.
5. **Same-file, different-work-shape.** When two candidate clusters touch the same file but have distinct decision axes (parse hygiene vs. auth policy; type safety vs. error handling), split only if one is autofix-ready and the other is needs-decision (batching interviews matters more than batching commits). If both are autofix-ready, or both are needs-decision on the same subsystem, merge — they will ship in one commit anyway. Record the merge rationale in the cluster's `Notes:`.
6. **Mechanical-cluster sanity check.** For clusters tagged `Autonomy: autofix-ready` with >3 findings, the cluster file's `Suggested session approach` block **must** walk at least one concrete implementation sketch — name the shape of the fix for the most non-trivial finding. "Mechanical substitution" alone is insufficient if any finding involves type narrowing, lifecycle changes, cross-module refactoring, or interaction with a pinned toolchain. If synthesis cannot sketch the shape, downgrade cluster `Autonomy` to `needs-decision`.
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones).
8. **Record per-cluster metadata:**

```
Cluster: {NN-slug}
Goal: {one sentence — what a session accomplishes when this cluster is done}
Files touched: {N files, list top 5}
Analysts involved: {list}
Severity spread: {Critical: N, High: N, Medium: N, Low: N}
Autonomy mix: {autofix-ready: N, needs-decision: N, needs-spec: N}
Autonomy (cluster): {autofix-ready | needs-decision | needs-spec}  — weakest constituent autonomy: needs-spec > needs-decision > autofix-ready
Est. session size: {Small (<2h) | Medium (half-day) | Large (full day+)}
Depends-on: {none | NN-slug[, MM-slug]}  — hard edge: fix requires another cluster's structure first
informally-unblocks: {none | NN-slug[, MM-slug]}  — soft edge: this cluster lands easier after another; not an ordering constraint
Pre-conditions: {none | bulleted list of "<file-or-cluster-ref>: <required state>"}
attribution: {none | NN-slug (caught-by: MM-slug)}  — fuzz-gap attribution convention
```

A finding belongs to **exactly one cluster**. If it genuinely spans two, pick the cluster where its fix is anchored; cross-reference in `Notes:`.

Clusters are the primary unit of the final report. The Executive Summary lists cluster slugs, not individual findings, so the user can navigate directly to the session they want to run.

### Attribution convention for fuzz-gap clusters

When a fuzz-gap cluster's recommended fix uncovers a production bug whose scope belongs to a different cluster (e.g., a fuzz test finds that `sanitizeSession('%')` throws; the scope belongs to an input-validation cluster), the bug fix lands in the **fuzz cluster's commit** — since that is where the new test is added — but the cluster file's `attribution:` field names the originating cluster. Example: `attribution: 04-input-validation (caught-by: 15-fuzz-gaps)`. Do not re-file the bug under the origin cluster; do not duplicate the finding.

### Pre-conditions inference

For any cluster that introduces a pass/fail gate (a coverage threshold flipped on, a new lint rule, a `tsc --noEmit` in CI, a new test asserted in release workflow), walk every file in the cluster's scope:

- List any that currently fail the gate as `Pre-conditions:` entries.
- Cross-reference any fix-findings from other clusters that would clear the gate — name them as `<NN-slug>: landed` pre-conditions when they exist.
- If the list is non-empty, the cluster's TL;DR block must acknowledge the pre-conditions in its Impact line (e.g., "gate enabled; currently-failing files fixed incidentally or batched in").

This is what prevents the "one-line CI flip" from going red because two in-scope files were already below the threshold.

## 7. Executive Summary selection

Include a **cluster** in the Executive Summary when **all** hold:

1. Cluster contains ≥1 Critical or High finding.
2. Finding confidences include ≥1 Verified or Plausible.
3. Cluster either spans >1 file **or** sits on a security-sensitive path (auth, secrets, subprocess, SQL, file IO, crypto, network boundary, deserialization).

Cap at 5 clusters. If more qualify, rank by:

1. Highest severity in cluster (Critical > High).
2. Highest confidence in cluster (Verified > Plausible).
3. Number of distinct files (more > fewer).
4. Alphabetical by cluster slug as final tiebreak.

Themes count as one item each for the cap; their severity is the highest single occurrence.

## 8. Validate checklist integrity

Walk every checklist line the agents emitted:

- **Bare `[x]` with no evidence** → demote to `[?]` and append `— defect: no evidence provided`.
- **`[x]` with evidence text containing "dropped", "skipped", "not filed", or otherwise indicating the analyst analyzed but chose not to file** → demote to `[?]` and append `— defect: malformed clean — use \`[x] clean — <reason absence is fine for tier>\` instead`. The "analyzed, absence is deliberate" case belongs under the tightened `[x] clean` shape (see `agent-prompt-template.md` line-shape rules), not under `[x]`.
- **`[x]` as a markdown table row** (any pipe-delimited form `| item | status | ... |` instead of the line shape) → demote the entire analyst's checklist to `[?] — defect: table-form checklist rejected; line shapes are load-bearing`. Do not attempt to parse the table into lines. Flag the analyst for a §10 re-dispatch with an explicit reminder about line shapes.
- **`[x] clean` with no sampling statement** → demote to `[?]` and append `— defect: scope of "clean" claim unspecified`.
- **`[-] N/A` that contradicts Scout's applicability flag OR mis-states the tier rule** → demote to `[?]`, append `— defect: contradicts {applicability|tier} rule; needs re-dispatch`, and flag the item for a targeted re-run.
- **`[~] deferred` without a tracking location** → demote to `[?]` and append `— defect: deferred without tracking pointer`. A legitimate `[~]` has a cluster slug, issue link, or file path; otherwise it is a disguised `[?]`.
- **`[~] deferred` with a tracking location** → accept verbatim. Add to the `Deferred this run` list in `not-in-scope.md` (see `report-template.md`).
- **Cross-scope cite** (a finding cites a `file:line` outside the analyst's declared scope globs) → **not a defect**. The finding is still valid, just mis-attributed. Action: move the finding to the correct analyst's by-analyst section with a `→ originally raised by {AGENT_NAME}` pointer; keep `Raised by:` pointing at the original agent so attribution is preserved. Track the count in §1b health check (`Cross-scope cites: N` under Run metadata). Two or more cross-scope cites from the same analyst is a §10 re-dispatch trigger for scope calibration.
- **Missing owned item** (agent did not emit a line for an item it owns) → synthesize `[?] inconclusive — agent did not address this item` and flag as defect.

Defect-demoted lines appear verbatim; do not silently fix them. The user needs to see where the analysis was weakest.

## 9. Draft META-1 entries

Walk the merged (and right-sized) findings. For any finding shape that repeats ≥3 times (across files or scopes), draft a one-line CLAUDE.md rule that would have prevented it.

Each META-1 entry:

```
- **{Draft rule}** — prevents: {comma-separated finding IDs or anchors}. Rationale: {one sentence}.
```

Collect under `meta.md` in the report directory. If nothing repeats ≥3 times, the file contains a single line: `_No recurring finding shapes surfaced this run._` — do not manufacture rules.

## 10. Targeted re-dispatch (optional)

Dispatch a **single targeted Opus Explore agent** to re-analyze specific paths when **any** of these hold:

- §1b flagged ≥2 health signals on the same analyst (strong signal of under-analysis).
- §1b flagged a high source-drop ratio where >50% of drops were "borderline" (over-aggressive filtering).
- §8 flagged a defect that matters (missing scope coverage, tier contradiction, applicability contradiction).
- §1b flagged `Suspiciously thin output` on an analyst AND that analyst's scope includes a security-sensitive surface (auth, subprocess, crypto, deserialization) — low finding count is load-bearing evidence only on surfaces where no findings is the norm.

**Not a trigger on its own:** few Executive Summary clusters. On a well-maintained repo with a clean §1b health check, fewer than 3 H/C clusters is the correct output, not a weakness. The repo is the signal. Specifically: **if §1b fired zero flags AND Executive Summary is short, do not re-dispatch.** Accept the shorter report and move on.

Merge the re-dispatch output back through §1–§8. Stop after one targeted pass — do not loop.

## 11. Re-synthesis for Depends-on resolution

Between the freeze and any later fix work, cluster merges can resolve findings in other clusters incidentally (e.g., a finding tagged `Depends-on: 01-ci-gate` that cluster 01's fix also handles). This is handled by the status-field bookkeeping layer, not the first-pass synthesis:

- **Canonical render of `Depends-on:`.** Slug only, no `cluster` prefix, no hash. One slug per line for multiple.
  - In cluster frontmatter: `Depends-on: 02-coverage-baseline`
  - In a finding body: `Depends-on: 02-coverage-baseline`
  - In TL;DR prose: "*Depends on cluster 02 (coverage-baseline): this cluster's gate-flip requires those fixes to land first.*"
  - In the README cluster index: adjacency marker `→ 02` rendered after the cluster's line.
- **Canonical render of `informally-unblocks:`.** Same shape. README index marker `⇢ 02` (soft edge, distinct from the hard `→`). These are not ordering constraints — fix coordinators may violate them without penalty if the sequencing doesn't matter.
- On the first synthesis pass, surface the dependency edge in both places: the downstream cluster frontmatter carries `Depends-on: {slug}`; the individual finding retains its `Depends-on:` line.
- When a cluster is later marked `Status: closed` with a `Resolved-in: <commit|tag>` field (see `report-template.md` cluster template), any downstream finding whose `Depends-on:` names that cluster is eligible for mark-as-resolved-by-dep. The user (or a targeted re-synthesis pass) confirms by reading the resolving commit and, if genuinely fixed, striking the finding through with `Status: resolved-by-dep (cluster NN-slug)` rather than re-opening the downstream cluster.
- Do **not** auto-resolve based on dep edges alone. "Cluster 01 merged" ≠ "finding X is fixed"; the edge is a prompt to check, not a conclusion.

## 12. Scope expansion is a legitimate outcome

Fix work on a cluster sometimes requires touching related code the analyst did not flag — e.g., unblocking `typecheck` to verify a fix uncovers six pre-existing type errors in adjacent files that must be repaired to get a green gate. This is not scope creep; it is the only honest way to land the cluster.

Rules:

- **Expand when a verification gate demands it.** If the cluster's own fix cannot be validated without the expansion (typecheck, lint, existing tests), expand.
- **Do not expand beyond the gate.** If the typecheck errors are in a module unrelated to the cluster's subsystem, stop at what is necessary to make the gate pass and file a new finding on the rest.
- **Document the expansion.** In the commit message, add a section named **`Incidental fixes`** listing each out-of-scope change with its file path and a one-line reason. This keeps the review trail honest and prevents "why did you touch this?" review churn.
- **Scope expansion does not promote `needs-spec` / `needs-decision` findings.** If expansion would require a spec or design call, stop and surface it.

Analysts never expand scope — this section is guidance for later fix sessions that consume the cluster file. Synthesis does not filter on it.

## 13. Freeze

Once §1–§10 are done, the synthesized set is frozen. Writing the report (Step 5 of the skill) is a pure rendering pass from this set — no new findings, no new dedup, no new severity adjustments, no new clustering. §11 and §12 describe what happens after freeze, during later fix work; they do not loop back into synthesis.
