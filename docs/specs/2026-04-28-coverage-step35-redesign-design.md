# Coverage analyst — Step 3.5 elimination & always-on coverage gate

**Skill:** `codebase-deep-analysis`
**Target version:** 3.9.0
**Status:** design (awaiting implementation plan)
**Author intent:** Step 3.5 is a half-step that asks the user to confirm a coverage command and pick an execution mode. The user dislikes both halves of that prompt: detection should drive behavior, and absence of coverage tracking should itself be a finding (severity by tier) rather than a question. Coverage analyst becomes a normal Step 3 dispatch, runs whatever it auto-detects unattended, and emits new findings when coverage tracking is missing or thresholds are undocumented.

## Goals

1. **Eliminate Step 3.5.** Coverage & Profiling Analyst dispatches in the Step 3 parallel fan-out like every other analyst. No "gated" / "execution-consent" branching.
2. **No mid-flow command-override prompt.** The orchestrator detects the project's coverage command and the analyst runs it unattended.
3. **Treat absence as signal.** Projects without any coverage tracking get a tier-graded finding (T1 = Low, T2 = Medium, T3 = High), not silent skipping.
4. **Encode threshold reasoning.** When coverage runs but no threshold is documented, file a Low-everywhere finding and recommend a tier-aware threshold via `max(tier-floor, current − 5pp)`. When a threshold IS documented, check fulfillment and file tier-graded findings on shortfall.
5. **Trim the Step 0 prompt to a sane confirmation gate.** Single proceed / abort / instruct prompt; the token-cost warning stays.
6. **Drop bench dynamic execution.** Bench detection adds runtime cost without a uniform signal. Static-only PROF-1/PROF-2 (already present) is enough.

## Non-goals

- **Not** changing the read-only invariant for any other analyst. Coverage remains the only analyst that may execute project commands; it just no longer needs an explicit consent gate to do so.
- **Not** auto-installing coverage tooling. If the detected command fails (missing dep, broken setup), the failure becomes a finding; the analyst does not `npm install` to make it work.
- **Not** adding a "skip coverage" CLI/flag plumbing. Users who want to opt out type that into the free-text slot at Step 0.
- **Not** refactoring the Coverage analyst into the Test Analyst. Their lenses are different (coverage = quantitative; tests = qualitative); the merge would lose information.

## Architecture

### Step 0 reshape

Before:

1. Capture skill revision.
2. Load deferred tools.
3. Detect coverage and bench commands (5-way provenance: auto-detected, none-detected, etc.).
4. **Consolidated consent prompt** — 5 options: run-both / coverage-only / bench-only / static-only / correct-commands / abort.
5. Record `EXECUTION_MODE`, `COVERAGE_CMD`, `BENCH_CMD`.
6. Check git state.
7. Pick non-clobbering report dir.
8. Create directory skeleton.

After:

1. Capture skill revision.
2. Load deferred tools.
3. Detect coverage command (bench detection drops).
4. **Lean confirmation prompt.** Single `AskUserQuestion` with three options:
   - **Proceed** — run the analysis as detected.
   - **Abort** — exit, no work done.
   - **Free-text instructions / questions** — user types directives the orchestrator should apply before proceeding (e.g., *"skip the bench static pass", "use senior tier on Frontend Analyst", "ignore the legacy/ directory", "what will this run actually do?"*). The orchestrator interprets, applies the directive (and answers the question if one was asked), and then re-prompts proceed / abort. Maximum two round-trips; after that, accept whatever the user last answered.
   - The prompt body still includes the existing token-cost warning verbatim: *"This run dispatches several analyst subagents in parallel and will consume a large number of tokens. It is best run when weekly quota has spare headroom."*
   - The prompt also tells the user: *"Coverage will run automatically if a tracking system is detected. To skip, type that into the instructions slot."*
5. Record `COVERAGE_CMD` (provenance: `auto-detected:<cmd>` or `none-detected`). Record any free-text directives accepted.
6. Check git state (no gate, just note in Run metadata).
7. Pick non-clobbering report dir.
8. Create directory skeleton.

The `EXECUTION_MODE` variable disappears. There is only one mode: "run if detected".

### Step 3.5 elimination

The "Step 3.5 — Coverage & Profiling (gated)" block in `SKILL.md` is removed. The execution-flow graph drops that node. The Coverage & Profiling Analyst is added to the normal Step 3 parallel-dispatch list along with Backend, Frontend, Database, Test, Security, Tooling, Docs, Styling.

The agent-prompt-template wrapper requires no changes — Coverage analyst already uses it. The substitutions just drop `{EXECUTION_CONSENT}` and `{DETECTED_BENCH_CMD}`.

### Coverage & Profiling Analyst behavior changes

**Drops:**
- The `Execution consent: granted | declined` branching block. There is no `declined` mode; the analyst always runs whatever it has.
- The bench dynamic pass. The analyst no longer invokes `{DETECTED_BENCH_CMD}`. Bench-target presence (PROF-1) and artifact freshness (PROF-2) stay as static checks.
- The `none-detected` static-fallback path's *reason* changes from "execution declined" to "no coverage system detected" — emitted as the new COV-4 finding rather than a checklist `[?] inconclusive`.

**Adds:**
1. **Coverage-system detection finding (COV-4).** When `{DETECTED_COVERAGE_CMD} = none-detected`, file COV-4 *Missing test coverage tracking system*. Severity by tier: T1 = Low, T2 = Medium, T3 = High. The Fix line points at common setups for the project's stack: `bun test --coverage`, `vitest --coverage`, `pytest --cov`, `cargo tarpaulin`, etc. Confidence = Verified (the absence is checkable).

2. **Threshold-documentation finding (COV-5).** When the coverage system runs but no threshold gate is documented in **either** the project's coverage config (`vitest.config.*`, `.nycrc*`, `coverage` block in `package.json`, `pyproject.toml`'s `[tool.coverage.report]`, etc.) **or** an instruction file (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README.md`), file COV-5 *Coverage threshold not documented*. Severity = Low at all tiers (per user direction). The finding's body explicitly tells the implementation session to **ask the maintainer for the appropriate hard / aspired thresholds and write them into `AGENTS.md` (or whichever instruction file the project uses)**, not just into the tooling config — agent-instruction files are the source of truth for project conventions in this skill's worldview. Confidence = Verified.

3. **Below-threshold finding (COV-6).** When the coverage run produces a number lower than either the documented threshold (if present) or the derived threshold `max(tier-floor, current − 5pp)`, file COV-6 *Coverage below documented/recommended threshold*. Severity by tier: T1 = Low, T2 = Medium, T3 = High. The body cites the actual percent and the threshold being checked against. Confidence = Verified.

**Threshold derivation rule:**

```
tier_floor = { T1: 50, T2: 65, T3: 80 }   # line coverage % only
recommended_floor = max(tier_floor[project_tier], current_coverage - 5)
```

The current `−5` clamp prevents the absurd "you have 90% line coverage, recommended floor is 50%" output on a hobby project that happens to be well-tested. Branch / function / statement coverage are deliberately not part of the recommendation — they get noisy fast and most projects don't track them. If the project's coverage config tracks them anyway, COV-6 still fires off the line metric only; the analyst notes the other metrics in the finding body but does not branch off them.

**Coverage-command failure handling (unchanged in spirit, restated):** If the auto-detected coverage command fails (broken setup, missing dep, hung process), the failure is the data — file it as COV-3 (config gap) with Confidence = Verified. Do not retry. Do not install dependencies. The static pass still runs.

**Static pass (unchanged):** Source→test mapping (COV-1), public-surface inference (COV-2), coverage-config review (COV-3), bench-target presence (PROF-1), existing-artifact freshness (PROF-2). All stay. Their relationship to the dynamic-pass numbers is unchanged: dynamic numbers upgrade Confidence; static inference is the floor.

### New checklist IDs

Added to `references/checklist.md` under the existing `## COV — Test coverage` section.

| ID | Item | Min tier | Owner |
|----|------|----------|-------|
| COV-4 | Missing test coverage tracking system — no `*.test.*` / `*.spec.*` runner config (`vitest.config.*`, `jest.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest.*]`, `bunfig.toml`, `Cargo.toml [profile]`, `go.mod` test conventions, etc.) AND no coverage-producing flag in any `package.json` script / Makefile target / justfile recipe / Taskfile target. Severity scales with tier: T1 hobby projects can reasonably skip, but absence is still a Low signal; T2 small-team projects need a tracking system to gate regressions; T3 production projects need it to ship. | T1 | Coverage |
| COV-5 | Coverage threshold not documented — coverage tracking exists but no hard/aspired threshold is named in the coverage config OR in an instruction file (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`). Fix: implementation session asks the maintainer for the threshold and writes it into the project's preferred instruction file (`AGENTS.md` is the default in this skill's worldview). Tooling-config-only documentation IS sufficient (e.g., `vitest.config.ts` containing `coverage: { thresholds: { lines: 70 } }` counts as documented); the AGENTS.md preference applies only when nothing is documented anywhere. | T1 | Coverage |
| COV-6 | Coverage below documented or recommended threshold — current line coverage falls under either (a) the documented threshold in coverage config / instruction file, or (b) the derived recommended floor `max(tier-floor, current−5pp)` where `tier-floor` is 50% / 65% / 80% for T1 / T2 / T3. Severity scales: T1 = Low (signal but not gating); T2 = Medium; T3 = High. | T1 | Coverage |

`COV-4` is min-tier T1 because the user explicitly said "minor for T1" — i.e., it fires at all tiers, just at varying severity. `COV-5` and `COV-6` are also T1-min for the same reason: the absence/shortfall is data at every tier; the severity slider does the right-sizing. The checklist's Min tier column controls *whether the item applies* (existing `[-] N/A — below profile threshold` mechanism); the per-finding severity is the runtime signal. These three IDs apply universally (Min tier T1) but emit at tier-graded severity at the analyst's discretion.

### Severity mapping

User said: T1 = minor / T2 = medium / T3 = major. Mapping to the skill's severity scale (Critical / High / Medium / Low):

| User term | Skill severity |
|-----------|----------------|
| minor | Low |
| medium | Medium |
| major | High |

So:

| Finding | T1 | T2 | T3 |
|---------|----|----|----|
| COV-4 (no system) | Low | Medium | High |
| COV-5 (undocumented threshold) | Low | Low | Low |
| COV-6 (below threshold) | Low | Medium | High |

### Coverage analyst roster row update

Current `agent-roster.md` row reads:

> **Coverage & Profiling Analyst** | Standard | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets | COV-1..COV-3, PROF-1..PROF-2 (new IDs — see coverage-profiling-prompt.md for definitions)

Updated row:

> **Coverage & Profiling Analyst** | Standard | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets, instruction files (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`) for documented thresholds | COV-1..COV-6, PROF-1..PROF-2

Owned IDs grow to COV-1..COV-6 (gain COV-4/5/6). Scope adds instruction files (the analyst now reads them to check for threshold documentation; previously this was Docs Analyst territory only). PROF-1/PROF-2 unchanged.

The "## Gated analyst: Coverage & Profiling" subsection in `agent-roster.md` is removed wholesale — the analyst is no longer gated. The execution-rights bullet ("the only analyst that may run commands") moves into a one-paragraph note inside the Coverage analyst's prompt instead, since it's analyst-specific rather than skill-wide policy.

### Free-text slot at Step 0 — interpretation rules

The free-text path needs a clear protocol so the orchestrator doesn't loop forever:

1. **User types text.** Orchestrator captures verbatim.
2. **Orchestrator classifies as one of:**
   - **Question** — interrogative form, no imperative directive. Orchestrator answers concisely (≤200 words) using only information already in scope (codebase map, detected commands, applicability flags). Then re-prompts: proceed / abort / more questions.
   - **Directive** — imperative form ("skip X", "use senior on Y", "ignore directory Z"). Orchestrator records the directive in Run metadata and applies it during dispatch. Then re-prompts: proceed / abort.
   - **Mixed** — both a question and a directive. Answer the question, record the directive, re-prompt.
3. **Round-trip cap = 2.** After two free-text iterations, the third option is hard-coded proceed / abort only. This prevents infinite back-and-forth.
4. **Directives the orchestrator can apply** (closed list, expandable in v-next):
   - `skip <analyst-name>` — drop that analyst from Step 3 dispatch (with the usual "Coverage Analyst skipped" Run-metadata note).
   - `use senior on <analyst-name>` — model-tier override; recorded in Run metadata as `Analyst override: per user request, ...`.
   - `ignore <path-or-glob>` — exclude from all analysts' scope (passed as an extra glob in `{SCOPE_GLOBS}`).
   - `set tier T<N>` — override Scout's tier classification; recorded in Run metadata.
   - Any directive outside this list: orchestrator declines and re-prompts ("That directive isn't supported in this run; proceed / abort / try again?").

Anything unrecognized (parser fails, the directive is too vague, etc.) is treated as a question and answered to the best of the orchestrator's ability, then re-prompted.

### Files to change

| File | Change |
|------|--------|
| `SKILL.md` | Reshape Step 0 (drop EXECUTION_MODE, drop bench detection, slim consent prompt to proceed/abort/instruct, document free-text protocol). Drop Step 3.5 entirely (delete the section, remove from execution-flow graph). Update Step 3 dispatch list to include Coverage. Drop or rewrite the "Common mistakes" entries about Step 3.5 consent. |
| `references/coverage-profiling-prompt.md` | Drop `{EXECUTION_CONSENT}` and `{DETECTED_BENCH_CMD}` substitutions. Drop the `granted` / `declined` branching block. Drop the bench dynamic pass. Add COV-4/5/6 logic with the severity-by-tier rule, threshold derivation rule, and AGENTS.md doc-target instruction. Add the "instruction files contain documented thresholds" reading rule. |
| `references/checklist.md` | Add COV-4, COV-5, COV-6 rows to the existing `## COV — Test coverage` section. Update the section's preamble to mention severity-by-tier scaling. |
| `references/agent-roster.md` | Update Coverage & Profiling row (scope grows to include instruction files; owned IDs grow to COV-1..COV-6). Remove the "## Gated analyst: Coverage & Profiling" subsection wholesale. |
| `references/synthesis.md` | Tiny change: §1b health check thresholds apply unchanged, but the "execution declined" footnote in §3 right-sizing (if present) becomes "no coverage system detected → COV-4". Search for any reference to `EXECUTION_MODE`, `static-only`, `EXECUTION_CONSENT` and rewrite or delete. |
| `references/structure-scout-prompt.md` | No change. Scout doesn't drive coverage decisions in either model. |
| `references/agent-prompt-template.md` | No change. Wrapper is generic. |
| `references/analyst-ground-rules.md` | Update the "no execution" rule's footnote: previously *"the Coverage & Profiling analyst has an explicit exception in Step 3.5"*; new wording *"the Coverage & Profiling analyst has an explicit exception described in its prompt — it may run a single auto-detected coverage command unattended"*. The dependency-freshness allowlist stays unchanged. |
| `VERSION` (codebase-deep-analysis) | Bump 3.8.0 → 3.9.0 |
| `VERSION` (implement-analysis-report) | Bump 3.8.0 → 3.9.0 (test-version-metadata.sh requires sync) |
| `plugin.json` | Bump 3.8.0 → 3.9.0 |

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| **Implicit trust of project commands.** With consent gate gone, a malicious project's coverage command runs on the developer's machine during analysis. | This is a deliberate trust posture: the user typed `/codebase-deep-analysis` knowing the skill exists and what it does. The Step 0 confirmation gate is the user's last opportunity to abort. The skill operates on the user's own machine, on a repo they're already running other commands against. The risk is real but no different from any other developer-initiated `npm test` / `pytest` invocation. |
| **Coverage runs slow down or hang the analysis.** A 15-minute coverage suite blocks the orchestrator for 15 minutes. | The existing `timeout: 900000` (15 min) Bash floor stays. If the run hangs past the timeout, the analyst files COV-3 (config gap: timeout) with `Confidence: Verified, Notes: command timed out at 15 min` and continues with the static pass. No retry. |
| **Threshold derivation feels arbitrary.** Why 50/65/80? Why `−5pp` clamp? | The numbers are calibration starting points, not enshrined truth. The skill's self-evolving feedback loop (`analysis-analysis.md` Part A) lets the v-next author retune based on real-run data. Document the choice in the Coverage analyst's prompt with a one-line "calibration: revisit on first 2-3 runs." |
| **COV-5 floods the report on every coverage-tracking project.** Most projects don't document thresholds in instruction files even when their coverage config has a threshold. | The finding fires only when **neither** source documents the threshold. If the coverage config has `lines: 70`, COV-5 doesn't fire (the threshold IS documented, just in tooling config). The "AGENTS.md preferred" rule is for projects with no threshold anywhere; the analyst's Fix line nudges toward AGENTS.md as the canonical home, but tooling-config-only is acceptable. |
| **Free-text directive parsing is brittle.** "Skip Frontend" vs "skip the frontend analyst" vs "no frontend please" — natural-language directives are hard to match. | The directive vocabulary is small and closed (5 directive shapes, see "Free-text slot interpretation rules"). The orchestrator is an LLM; matching natural-language phrases to a 5-directive vocabulary is well within capability. When matching fails, the orchestrator treats input as a question and answers it; the user can re-issue more clearly. The 2-round-trip cap prevents runaway loops. |
| **Bench static-only pass loses regression detection.** The dynamic-bench pass occasionally caught real regressions on projects with checked-in baselines. | The use case was rare (committed bench baselines exist on a single-digit percentage of repos). PROF-1 (missing bench target) and PROF-2 (stale artifacts) cover the remaining static signal. Users with mature bench infrastructure run their bench locally and don't need the analysis skill to do it for them. |
| **The "run the coverage command" rule still requires the command to be invokable.** Lockfile out of date, deps missing, tools not installed — the command fails at the harness. | Already covered: failure → COV-3 finding, fall back to static. The user gets useful output either way. The fix-time analyst (`implement-analysis-report`) sees COV-3 + the static-pass findings and can decide whether to bother fixing the dynamic-pass enabler at all. |
| **"Detect coverage" heuristics get out of date.** New runners (e.g., Bun's eventual native coverage, `swc-coverage`) don't get detected. | Detection list lives in `SKILL.md` Step 0 (alongside the existing detection list for `package.json` / `Makefile` / `justfile` / `Taskfile*` keys). Update during normal skill maintenance — same as the dependency-freshness command allowlist. The Coverage analyst's Summary section already records `Coverage command provenance: auto-detected:<cmd> | none-detected`, surfacing detection failures for v-next retuning. |

## Self-evolving feedback loop

`analysis-analysis.md` Part A (Step 6) captures runtime feedback. After 1–2 runs of v3.9, the v-next author should look for:

- COV-4 false positives (project has coverage tracking but the detector missed the runner config). If common, expand the detector.
- COV-5 mass-emission patterns (every project gets COV-5 — "undocumented threshold" is universal). If common, drop the AGENTS.md emphasis and accept tooling-config-only as documentation.
- COV-6 vs derived-threshold disagreement (current is below tier-floor but above current−5pp, so the clamp is doing work — is the right thing happening?).
- Free-text directive distribution (which directive shapes are actually used; which never get used; which produce parsing failures).

Same feedback contract as every other analyst — no special instrumentation needed.

## Out of scope

- **CLI flags.** No `--no-coverage` or `--static-only` flags. The free-text slot at Step 0 covers the same need.
- **Automatic threshold-config writes.** The Coverage analyst does not modify project files. COV-5's Fix is a directive to the implementation session, not an autofix.
- **Coverage diff vs baseline.** "Did this PR drop coverage by N pp?" is a different feature; out of scope here.
- **Per-metric threshold derivation.** Branch / function / statement coverage are deliberately not part of the recommendation logic. If the project's config tracks them, COV-6 cites them in the body for context but doesn't fire on their shortfall.
- **Project-language-specific tooling intelligence.** Knowing that `cargo tarpaulin` exists and what it costs is general knowledge baked into the analyst's prompt, but the analyst doesn't carry per-language threshold-floor calibrations. T1/T2/T3 floors are language-neutral.
