# Synthesis & dedup

Run this after every dispatched analyst has returned. Do not start writing the report until every step below has run.

## 1. Collect

Put each agent's `Findings` block into an indexed list. Tag every entry with the raising agent's name. Keep the original text verbatim — no rewrites yet.

## 1b. Analyst output health check

Before dedup, assess each analyst's output for signs of shallow analysis. Flag but do not auto-reject — the flags feed into §10 (targeted re-dispatch) and into the Run metadata so the user can see where coverage was weakest.

| Signal | Threshold | Action |
|--------|-----------|--------|
| **Suspiciously thin output** | <3 findings for an analyst whose scope covers >20 files. If the user overrode analysts to a senior tier, treat this as weaker signal and look harder at checklist sampling quality; if an analyst ran junior, use <5 findings as the warning floor. | Flag: `{AGENT_NAME}: {N} findings across {M}-file scope — possible under-analysis`. Candidate for §10 re-dispatch. |
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

Frontend/Styling joint items (`FE-1`, `FE-6`, `FE-7`, `FE-8`, `FE-21`, `FE-22`, `FE-23`, `A11Y-3`, `UX-1`, `PERF-2`) follow the same pattern with the Styling Analyst lens-split documented in `agent-roster.md`:

```
FE-1 [x] (frontend) src/components/Header.tsx:42 — inline style on tag suggests missing prop typing
FE-1 [x] (styling) src/components/Header.tsx:42 — one of 47 magic colors; consolidate via tokens
```

The findings themselves dedup by anchor per §2; ownership collision is a checklist-display concern, not a findings concern.

## 5. Promote cross-cutting themes

If the same pattern appears in **≥3 distinct files across ≥2 agents** after right-sizing, create a theme entry:

The Styling Analyst's optional `### System inventory` block (z-index inventory, magic-number census, custom-property roll-up, breakpoint vocabulary, selector-to-markup x-ref — see `styling-prepass.md`) feeds this step directly. An inventory entry that recurs across ≥2 source files is a theme candidate; promote it the same way as analyst findings, with `Raised by: Styling Analyst (system inventory)` as the attribution.

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
4. **Apply floor rule.** Merge singleton clusters (1 finding) into the nearest topical cluster by default. A singleton survives only when **all** hold: (a) its fix is genuinely a self-contained session, (b) no other cluster shares its file or subsystem, AND (c) no other cluster shares its decision axis (autofix vs. needs-decision vs. needs-spec). "Topically isolated but small" is not enough — merge upward to the weakest adjacent cluster rather than ship a singleton. Expect ≤1 singleton per 10 clusters after synthesis. If 3+ unrelated findings have no better topical home but share severity band and decision axis, batch them into an explicit honest catch-all cluster (`server-low-cleanup`, `security-low-defenses`) and say so in `Notes:`; this is different from an accidental `misc-{severity}` fallback.
5. **Same-file, different-work-shape.** When two candidate clusters touch the same file but have distinct decision axes (parse hygiene vs. auth policy; type safety vs. error handling), split only if one is autofix-ready and the other is needs-decision (batching interviews matters more than batching commits). If both are autofix-ready, or both are needs-decision on the same subsystem, merge — they will ship in one commit anyway. Record the merge rationale in the cluster's `Notes:`.
6. **Mechanical-cluster sanity check.** For clusters tagged `Autonomy: autofix-ready` with >3 findings, the cluster file's `Suggested session approach` block **must** walk at least one concrete implementation sketch — name the shape of the fix for the most non-trivial finding. "Mechanical substitution" alone is insufficient if any finding involves type narrowing, lifecycle changes, cross-module refactoring, or interaction with a pinned toolchain. If synthesis cannot sketch the shape, downgrade cluster `Autonomy` to `needs-decision`.
7. **Name clusters.** Use kebab-case slugs that describe the work, not the area (`swap-console-log-for-pino`, not `logging`). Prefix numbering reflects recommended fix order (Critical/High first, independent clusters before dependent ones). The Styling Analyst uses a closed cluster-hint vocabulary (documented in its prompt) to prevent slug sprawl on visual-layer findings — `z-stack-cleanup`, `cascade-spaghetti`, `design-token-consolidation`, `breakpoint-unification`, `dead-styles`, `tailwind-config-cleanup`, `css-in-js-render-path`, `shorthand-longhand-bugs`, `style-system-consolidation`, `nesting-and-specificity`, `scope-leak-fix`, `style-dedup-and-base-classes`, `class-naming-pass`, `inline-style-and-important`, `palette-and-contrast`, `css-bundle-trim`. The Accessibility Analyst (v3.10) uses its own closed cluster-hint vocabulary — `semantic-markup-pass` (A11Y-1, A11Y-4, A11Y-5), `keyboard-and-focus` (A11Y-2, A11Y-7, UX-2), `aria-cleanup` (A11Y-6), `motion-respect` (A11Y-8), `form-a11y` (A11Y-9 + FE-18 joint), `touch-targets` (A11Y-10), `palette-and-contrast` (A11Y-3 joint with Styling — same slug as Styling's hint, collapsing during reshape is correct). Same-hint findings from multiple analysts merge during reshape (step 2 above). Future analysts may adopt the closed-vocabulary pattern; this is not a cross-skill registry, just per-analyst prompt discipline.
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
Commit-guidance: {empty | single-line cluster-specific commit note}  — see report-template.md field reference
model-hint: {junior | standard | senior}  — see "Model-hint selection" below
```

### Model-hint selection

Populate `model-hint:` on every cluster. Use these rules; the field is not user-facing but drives `implement-analysis-report`'s per-cluster subagent dispatch.

- **Default:** `standard`.
- **Downgrade to `junior` when ALL hold:** `Autonomy: autofix-ready`, highest-severity-in-cluster is Low, no finding involves type narrowing (`any → unknown`, generic constraint changes, union refinement), no finding involves async/lifecycle changes (signal handling, cancellation, race fixes), no finding touches cross-module refactoring (shared-abstraction extraction, module split/merge).
- **Upgrade to `senior` when ALL hold:** `Autonomy: needs-spec`, highest-severity-in-cluster is High or Critical, cluster spans >5 distinct files, AND the fix requires maintainer interview + spec design synthesized into code. `senior` is the expensive option — reserve for clusters where the standard tier would likely return shape B ("cannot implement without further decision").
- **Upgrade to `senior-1m` when ALL hold (v3.10):** `Autonomy: needs-spec`, highest-severity-in-cluster is High or Critical, AND **either** cluster spans >15 distinct files **OR** cluster's source-file footprint exceeds an estimated 50k LOC (e.g., entire backend module rewrite, cross-package monorepo refactor). The fix subagent needs to hold the entire affected subsystem in context simultaneously — standard 200k context fragments the work.

When in doubt: default to `standard`. The hint is a cost optimization, not a correctness constraint; `iar` may override based on its own runtime signal (e.g., a standard-tier cluster that returns shape B twice might escalate to senior on its third attempt — out of scope for this version).

### Effort-hint selection (v3.10)

Populate `effort-hint:` on a cluster ONLY when one of the closed-list triggers fires. Otherwise omit the field (which means `default`). Vocabulary: `default | high | max`.

- **Set `effort-hint: max` when ALL hold:** the cluster has `model-hint: senior-1m` AND `Autonomy: needs-spec`. Synthesizing a fix design and writing code in one pass at this complexity needs maximum reasoning depth. Same model, more thinking budget.

The closed list is intentionally short. Most clusters do not get an effort-hint (omitted = default effort). The `iar` cluster execution honors `effort-hint:` at dispatch when present.

The skill also recommends `effort-hint: max` on the synthesis pass itself when the synthesis-Senior-1M auto-escalation trigger fires (T3 + ≥10 active analysts + ≥100 findings, OR text ≥50k tokens). That recommendation lives in `SKILL.md`'s Step 4 / Model-selection sections; synthesis does not write its own cluster file so this hint is documented in Run metadata under `Effort overrides:` for the retrospective.

A finding belongs to **exactly one cluster**. If it genuinely spans two, follow the cross-cluster attribution rule below.

### Cross-cluster finding attribution rule

When a finding legitimately spans two or more clusters (e.g., a security finding whose fix touches both the auth middleware and the path-traversal sanitizer):

1. **Place it under the cluster whose fix resolves the root cause.** This is the cluster whose session-scope work would make the finding disappear even if no other cluster shipped. Anchor on *cause*, not *surface* — the path-traversal symptom might appear in the file-upload cluster's files, but if the root cause is missing auth on the upload endpoint, the finding belongs in the auth cluster.
2. **In the owning cluster's `Findings:` block, add a `Touches:` sub-bullet** naming every other cluster's scope the finding intersects: `Touches: cluster 03-path-traversal`.
3. **In the touched clusters' bodies, emit a `See cluster NN-slug finding '{title}'` line** under a `## Cross-references` section (create the section if absent). No body duplication.
4. The attribution cluster is the single source of truth. Updates to the finding (severity, fix, etc.) happen only in the attribution cluster.

### Sanity check on thematic-mixed large clusters

For clusters with >7 findings that are **not** `Autonomy: autofix-ready` (i.e., the fix shape is mixed or includes decisions), the cluster's `Suggested session approach` block must demonstrate **single session focus** — name the one thread that ties all findings together. If synthesis cannot name a single thread in 2–3 sentences, split the cluster. "Related but heterogeneous" is not session focus; subsystems with mixed decision axes compound mental-model load across the session.

The >7 threshold is intentionally looser than the mechanical-autofix >3 threshold (§6 step 6) — thematic clusters have natural cohesion where mechanical ones do not.

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
- **Unsourced version claim** (a `DEP-1`, `DEP-6`, `TOOL-3` finding, or any finding whose `Fix:` names a version bump, without a source citation for the "latest" version) → demote Confidence to `Plausible` and append `— defect: unsourced version claim; analyst cited version without running <pm> outdated, web-searching, or querying the registry`. Autonomy cannot stay `autofix-ready` after this demotion. See `analyst-ground-rules.md` "Dependency freshness checks" for the required source forms.
- **Missing owned item** (agent did not emit a line for an item it owns) → synthesize `[?] inconclusive — agent did not address this item` and flag as defect.

Defect-demoted lines appear verbatim; do not silently fix them. The user needs to see where the analysis was weakest.

## 9. Draft META-1 entries

Walk the merged (and right-sized) findings. For any finding shape that repeats ≥3 times (across files or scopes), draft a META-1 entry. Two cases — pick the one that matches:

### Case 1 — New pattern without an existing rule

Grep the project's instruction-file docs (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, top-level `README.md`, `docs/*.md`) for the rule's subject. If no match, you're in Case 1. Draft a one-line rule for the project's preferred agent-instruction file that would have prevented the finding:

```
- **{Draft rule}** — prevents: {comma-separated finding IDs or anchors}. Rationale: {one sentence}.
```

### Case 2 — Existing rule violated N times

If the project's instruction-file docs already name the rule being violated (e.g., an agent-instruction file says "always sanitize filenames before passing to the filesystem" and the findings show 4 places this wasn't done), the meta-issue is **enforcement**, not rule design. A new rule duplicating the existing text is pure noise. Instead, draft an enforcement mechanism:

```
- **Enforce {existing rule name}:** add {tool/mechanism} check — prevents: {IDs}. Rationale: rule already exists in {doc path}, N violations this run indicate enforcement gap.
```

Choose the mechanism:

- If a lint rule fits (ESLint/biome/ruff/pylint/rubocop/clippy), name it: *"add a biome rule `no-unsafe-paths` that forbids raw string concatenation into `fs.open`"*.
- If a pre-commit or pre-push hook fits (simple grep / regex gate), name it: *"add a pre-commit grep forbidding `ffprobe` invocations outside `lib/probe/`"*.
- If a CI job fits (type/lint/test check that the project already runs), extend it: *"extend `tsconfig.check.json` include to cover `tests/api/**` so the Locals.ctx type gap is caught in CI"*.
- If no mechanical catch is available, draft a **hard-stop entry** for the project's pre-dispatch checklist: *"before committing a fix touching upload endpoints, re-read the upload-safety rule in the agent instructions — rule violated 4 times this run, no automated catch"*.

### Output

Collect all entries under `meta.md` in the report directory. Mix Case 1 and Case 2 entries freely; each entry's format makes its kind obvious. If nothing repeats ≥3 times, the file contains a single line: `_No recurring finding shapes surfaced this run._` — do not manufacture rules.

## 10. Targeted re-dispatch (optional)

Dispatch a **single targeted senior-tier Explore agent** to re-analyze specific paths when **any** of these hold:

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

### Shape changes during fix work

Some fix sessions produce changes the cluster did not anticipate but that are distinct from scope-expansion-for-gates:

- **Drafted work that must be deleted.** A subagent drafts tests following TDD, then discovers the test approach won't work because of test-runner pollution (Bun's process-global `mock.module`), fixture-sharing limits, or platform-specific blockers. The tests must be deleted, not just left failing.
- **Planned helpers that collapse.** A cluster's approach assumed a helper function was needed; the implementation is simpler and the helper never materializes.
- **Type annotations or guards that become unnecessary** after a refactor changes the surface.

These are **shape changes**, not gate-unblocks. Document them in the commit message under a `**Shape changes**` section (parallel to `Incidental fixes`, same placement in the message body). One line per change: what was planned, what actually landed, why.

- If a shape change reverses a cluster's named goal (cluster said "add 5 tests", fix landed 2 and deleted 3 as unimplementable), flip `Status: partial` and name the blocker in `Resolved-in: <SHA> (partial — <blocker>)`.
- If a shape change is additive-only (cluster said "extract helper", fix landed without the helper but with the desired behavior), keep `Status: closed` — the cluster's goal shipped, the shape just differed.
- Shape changes do NOT require a new finding. They are outcomes of a cluster already in the report.

### Enshrined-test check before fix work

Before executing a fix for any `Autonomy: autofix-ready` cluster, the fix agent (or the cluster file's consumer) must check for tests that enshrine the pre-fix behavior. The check: grep the project's test files for hard-coded values that the fix would make impossible (e.g., a test asserting `'cap-a'` is accepted when the fix makes only UUIDs valid). Any enshrined test becomes an incidental-fix obligation.

Analysts are expected to flag enshrined tests at report time where they can (see `analyst-ground-rules.md` Fix-line rules). When the analyst missed one, fix-time catch keeps the cluster closable — delete or rewrite the enshrined test under `Incidental fixes` rather than leaving a red gate.

Analysts never expand scope themselves — this section is guidance for later fix sessions that consume the cluster file. Synthesis does not filter on it.

## 13. Freeze

Once §1–§10 are done, the synthesized set is frozen. Writing the report (Step 5 of the skill) is a pure rendering pass from this set — no new findings, no new dedup, no new severity adjustments, no new clustering. §11 and §12 describe what happens after freeze, during later fix work; they do not loop back into synthesis.
