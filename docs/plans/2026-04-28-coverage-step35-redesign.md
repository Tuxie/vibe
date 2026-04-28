# Coverage Analyst — Step 3.5 Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate Step 3.5 of the codebase-deep-analysis skill, fold the Coverage & Profiling Analyst into the normal Step 3 parallel dispatch with no consent gate, simplify Step 0 to proceed/abort/instruct, drop bench dynamic execution, and add COV-4/5/6 (missing-coverage / undocumented-threshold / below-threshold) checklist IDs.

**Architecture:** Documentation-only changes to one skill (no executable code). Each task edits one file (or one logical unit), runs verify greps, and commits. Final task bumps version + runs the metadata validator.

**Tech Stack:** Markdown documentation under `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/`. Bash validator `plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`.

**Spec:** `docs/specs/2026-04-28-coverage-step35-redesign-design.md`

**Note on TDD shape:** Same as v3.8.0 — documentation work, no test loop. Each task has explicit verify steps (greps, line counts, metadata validator on the version-bump task) instead of a failing-test loop.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md` | Modify | Add COV-4, COV-5, COV-6 rows; update `## COV` preamble with severity-by-tier note |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md` | Rewrite (large diff) | Drop EXECUTION_CONSENT branching + bench dynamic pass; add COV-4/5/6 logic; add threshold derivation rule |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md` | Modify | Update Coverage row scope/owned-IDs; delete "## Gated analyst: Coverage & Profiling" subsection |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md` | Modify | Rewrite two Step-3.5 footnotes (forbidden-commands rule, dependency-freshness allowlist note) |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md` | Modify | Strip residual `EXECUTION_MODE` / `static-only` references (small if any) |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md` | Rewrite (large diff) — Step 0 | Reshape Step 0: drop bench detection, drop 5-option execution-mode picker, add 3-option proceed/abort/instruct prompt with free-text directive protocol |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md` | Rewrite (large diff) — Step 3.5 elimination | Delete `## Step 3.5` section; update execution-flow graph; update References table; rewrite "Common mistakes" entries that name Step 3.5 |
| `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` | Modify | Bump 3.8.0 → 3.9.0 |
| `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` | Modify | Bump 3.8.0 → 3.9.0 |
| `plugins/codebase-deep-analysis/.claude-plugin/plugin.json` | Modify | Bump version field 3.8.0 → 3.9.0 |

`structure-scout-prompt.md` and `agent-prompt-template.md` are intentionally NOT modified.

Order of tasks is bottom-up (smaller / foundational files first, SKILL.md last) so that when SKILL.md is rewritten the references it points at are already in their new shape.

---

### Task 1: Add COV-4, COV-5, COV-6 to checklist.md

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`

The existing `## COV — Test coverage` section (around line 299) has COV-1, COV-2, COV-3. We add three rows after COV-3 and update the preamble to mention severity-by-tier scaling.

- [ ] **Step 1: Locate the COV section**

Run: `grep -n "^## COV \|^| COV-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: one `## COV` heading and three `| COV-` rows (COV-1, COV-2, COV-3).

- [ ] **Step 2: Update the section preamble**

Edit. Find this exact block (the COV section header and current preamble):

```
## COV — Test coverage

Runs in the gated Step 3.5 pass. Items that require running the coverage command emit `[?] inconclusive — execution declined` when the Step 0 preflight selected `static-only`; the static analogues still run.
```

Replace with:

```
## COV — Test coverage

Owned by the Coverage & Profiling Analyst, dispatched in the regular Step 3 parallel fan-out. The analyst auto-detects the project's coverage command and runs it unattended; if no coverage system is detected, COV-4 fires with severity scaled to project tier. Static checks (source→test mapping, public-surface inference, config review) always run regardless of dynamic-pass success. COV-4 / COV-5 / COV-6 emit at tier-graded severity (Low / Medium / High mapping to user-stated minor / medium / major); the checklist Min tier column controls applicability (the items always apply, hence T1) while the analyst chooses the per-finding severity.
```

- [ ] **Step 3: Add COV-4, COV-5, COV-6 rows**

Edit. Find this exact block (COV-3 row immediately followed by the next `## ` section heading — `## PROF`):

```
| COV-3 | Coverage-config gaps — exclusions that hide real code (e.g., `**/*.ts` without narrowing), no coverage threshold gate in CI where one would fit the project tier | T2 | Coverage |

## PROF — Profiling / benchmarking
```

Replace with:

```
| COV-3 | Coverage-config gaps — exclusions that hide real code (e.g., `**/*.ts` without narrowing), no coverage threshold gate in CI where one would fit the project tier | T2 | Coverage |
| COV-4 | Missing test coverage tracking system — no `*.test.*` / `*.spec.*` runner config (`vitest.config.*`, `jest.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest.*]`, `bunfig.toml`, etc.) AND no coverage-producing flag in any `package.json` script / Makefile target / justfile recipe / Taskfile target. Severity scales with tier: T1 = Low, T2 = Medium, T3 = High. T1 hobby projects can reasonably skip but absence is still a Low signal; T2 small-team projects need it to gate regressions; T3 production projects need it to ship | T1 | Coverage |
| COV-5 | Coverage threshold not documented — coverage tracking exists but no hard/aspired threshold is named in the coverage config OR in an instruction file (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`). Severity = Low at all tiers. Tooling-config-only documentation IS sufficient (e.g., `vitest.config.ts` with `coverage: { thresholds: { lines: 70 } }` counts as documented); the AGENTS.md preference applies only when nothing is documented anywhere. Fix: implementation session asks the maintainer for the threshold and writes it into the project's preferred instruction file | T1 | Coverage |
| COV-6 | Coverage below documented or recommended threshold — current line coverage is below either (a) the documented threshold from coverage config / instruction file, or (b) the derived recommended floor `max(tier_floor, current − 5pp)` where `tier_floor = 50% / 65% / 80%` for T1 / T2 / T3. Line metric only — branch / function / statement get noisy. Severity scales with tier: T1 = Low, T2 = Medium, T3 = High | T1 | Coverage |

## PROF — Profiling / benchmarking
```

- [ ] **Step 4: Verify**

Run: `grep -c "^| COV-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `6` (six rows: COV-1..COV-6).

Run: `grep -c "Owned by the Coverage & Profiling Analyst, dispatched in the regular Step 3" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `1`.

Run: `grep -c "execution declined" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `0` (the old preamble text mentioning "execution declined" should be gone).

- [ ] **Step 5: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: add COV-4..COV-6 checklist IDs

COV-4 missing-coverage-system (T1 Low / T2 Medium / T3 High),
COV-5 threshold-not-documented (Low everywhere), COV-6 coverage-
below-threshold (T1 Low / T2 Medium / T3 High). Preamble rewritten
to reflect that the Coverage Analyst dispatches in the regular Step
3 parallel fan-out — no longer "the gated Step 3.5 pass".

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Rewrite coverage-profiling-prompt.md

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`

The current prompt has an `Execution consent: granted | declined` branching block, a bench dynamic pass, and inherited Step 3.5 framing. We rewrite the file in place to drop those, add COV-4/5/6 logic, and add the threshold derivation rule. Because the diff is large and structural, this task uses Write (after Read) rather than per-section Edit.

- [ ] **Step 1: Read the current file (required before Write)**

Run: `wc -l plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: ~111 lines (the current shape).

- [ ] **Step 2: Write the new file content**

Write to `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md` with this exact content:

```markdown
# Coverage & Profiling Analyst prompt

This analyst is the **only** analyst in the skill that may execute project commands. It dispatches in the regular Step 3 parallel fan-out alongside every other analyst. There is no consent gate at dispatch time and no separate Step 3.5 — the orchestrator's Step 0 confirmation gate (proceed / abort / instruct) is the single point at which the user can prevent the run.

Fill placeholders `{SKILL_DIR}`, `{CODEBASE_MAP_PATH}`, `{PROJECT_TIER}`, `{TIER_RATIONALE}`, `{OWNED_CHECKLIST_ITEMS}`, `{INSTRUCTION_FILES}`, `{APPLICABILITY_FLAGS}`, `{DETECTED_COVERAGE_CMD}` before dispatching.

**Command provenance.** `{DETECTED_COVERAGE_CMD}` arrives as one of two shapes:

- `auto-detected:<cmd>` — the orchestrator found this in `package.json` / `Makefile` / `justfile` / `Taskfile*` during Step 0 preflight.
- `none-detected` — no candidate found at Step 0; the analyst files COV-4 *Missing test coverage tracking system* and runs the static-only pass.

Never invent commands. Never treat `none-detected` as permission to pick a default. Bench dynamic execution does not exist in this version — bench presence is a static check (PROF-1) only.

Copy the text between the fences into the Agent prompt.

```
You are the Coverage & Profiling Analyst for a codebase deep analysis. Your job is to surface (1) where the test suite is not actually covering the code; (2) where coverage is not tracked at all; (3) whether coverage thresholds are documented and met; (4) where performance-sensitive work lacks a repeatable measurement loop. Your output follows the same strict finding format as every other analyst.

## First action — Read ground rules

Use the Read tool on `{SKILL_DIR}/references/analyst-ground-rules.md` (entire file). Apply it verbatim. This analyst has one extra rule — see "Extra rule" below — but every other rule in ground-rules applies unchanged.

## Project tier: {PROJECT_TIER}

{TIER_RATIONALE}

## Applicability flags

{APPLICABILITY_FLAGS}

## Coverage command: {DETECTED_COVERAGE_CMD}

**This is the branch point.**

- **`auto-detected:<cmd>` —** before invoking, cross-reference `package.json` / `Makefile` / `justfile` / `Taskfile*` to confirm the command is defined there and has not rotted. If confirmation fails, treat as `none-detected` and file COV-4. Otherwise run the command exactly once. Capture output (text or parsed `coverage-summary.json` / `lcov.info`). Do not run with `--watch`. Do not retry on failure.
- **`none-detected` —** do not run anything. File **COV-4 Missing test coverage tracking system** with severity scaled to project tier (T1 = Low, T2 = Medium, T3 = High) and Confidence = Verified (the absence is checkable). The Fix line names common runners for the project's stack (e.g., `bun test --coverage`, `vitest --coverage`, `pytest --cov`, `cargo tarpaulin`).

If the coverage command runs and fails (broken setup, missing dep, hung process, non-zero exit with no usable output), file the failure as **COV-3 Coverage-config gaps** with Confidence = Verified and Notes naming the failure mode (e.g., *"command exited with status 2; output: <stderr summary>"*). Do not install dependencies. Do not retry. The static pass still runs.

## Instruction files to read first

{INSTRUCTION_FILES}

These are also load-bearing for COV-5 — see "Threshold-documentation check" below.

## Codebase map

Read `{CODEBASE_MAP_PATH}` once. Don't paste it into output.

## Extra rule beyond analyst-ground-rules.md

**Bash timeout floor.** Every Bash invocation you make to run `{DETECTED_COVERAGE_CMD}` MUST pass `timeout: 900000` (15 minutes) explicitly. Real-world coverage suites routinely run 5–12 minutes; the harness's default 2-minute Bash timeout will kill them mid-run. If one invocation hangs past the 15-minute floor, that is the data — file the timeout as COV-3 (`Notes: command timed out at 15 min`) and continue.

You may also use the read-only outdated-command allowlist in `analyst-ground-rules.md` §6 if a `Fix:` line cites a tool version. No other commands beyond the coverage command and the dependency-freshness allowlist are permitted.

## Static pass (always runs)

Produce these sub-analyses without invoking anything:

1. **Source→test mapping.** For each top-level source directory in scope, enumerate the test files that plausibly cover it (matching basename, shared directory ancestor, explicit import in a test). Flag source files with no plausible test as candidates for COV-1.
2. **Public-surface coverage inference.** Collect exported functions / classes, HTTP route declarations, CLI subcommand registrations. For each, check whether any test file imports or references the exported name. Missing references → COV-2.
3. **Coverage-config review.** If `vitest.config.*`, `jest.config.*`, `.nycrc*`, `coverage` block in `package.json`, `pyproject.toml`'s `[tool.coverage.*]`, or equivalent exists, read it. Flag broad `include` / narrow `exclude` that probably hides real code → COV-3. Note any documented threshold here for the COV-5 / COV-6 checks.
4. **Threshold-documentation check.** Read `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and `README.md` (the actual files that exist; from `{INSTRUCTION_FILES}`). Search for explicit coverage-threshold language: percent values cited as floors / targets / minima, lines with shapes like "coverage must be ≥ 70%", "we target 80% line coverage", "minimum coverage: 65%". Cross-reference against the coverage-config threshold from step 3.
   - **If documented in either place:** record the documented threshold for COV-6 comparison.
   - **If documented in NEITHER:** file COV-5 *Coverage threshold not documented* with Severity = Low (at all tiers). Fix line: *"ask the maintainer for the appropriate hard / aspired thresholds and write them into AGENTS.md (or whichever instruction file the project uses)"*. Confidence = Verified.
5. **Bench-target presence check.** Look for `bench`, `benchmark`, `profile` scripts in `package.json`, Makefile, justfile, Taskfile. If a path is flagged elsewhere in the run as perf-sensitive (PERF-* findings in hand, or code comments indicating hot path, or existing `bench/` directory) but no bench target exists → PROF-1.
6. **Existing-artifact freshness.** Enumerate `*.prof`, `flamegraph.*`, `bench/results/*`, `coverage/` artifacts already in-repo. Cross-reference with `git log -1 --format='%ci' <path>` on the artifact vs. `git log -1 --format='%ci' <referenced source>`. Stale or orphaned artifacts → PROF-2.

## Dynamic pass (only if `{DETECTED_COVERAGE_CMD}` is `auto-detected:<cmd>`)

1. **Coverage run.** Invoke `{DETECTED_COVERAGE_CMD}` once with timeout 900000.
2. **Interpret output.** Emit findings for:
   - Files at 0% line coverage (COV-1 — upgrade Confidence from Plausible to Verified).
   - Public-surface entry points at <20% (COV-2).
   - Coverage config that visibly excludes large real chunks (COV-3 — upgrade or augment the static-pass version).
3. **Threshold-fulfillment check.**
   - Compute the **derived recommended floor** even if a threshold is documented: `max(tier_floor, current_line_coverage − 5pp)` where `tier_floor = { T1: 50, T2: 65, T3: 80 }`. Line coverage only.
   - **If a threshold is documented** (from static-pass step 4): compare current line coverage against the documented threshold. If `current < documented`, file COV-6 *Coverage below documented threshold* with severity scaled to project tier (T1 = Low, T2 = Medium, T3 = High). Body cites both numbers.
   - **If no threshold is documented** (COV-5 already filed): compare current line coverage against the derived floor. If `current < derived_floor`, file COV-6 *Coverage below recommended floor* with severity scaled to tier. Body cites the current number, the derived floor, and the formula.
   - The clamp `current − 5pp` prevents recommending a floor lower than the project already achieves on a well-tested hobby project (T1 with 90% coverage gets a recommended floor of 85%, not 50%).

When the dynamic coverage run succeeds and produces authoritative per-file numbers, keep static source→test and public-surface inference as supporting evidence; do not duplicate inferior static-inference items as separate Findings for the same files unless they add a distinct failure mode.

**What you do not do, even with a successful dynamic run:**

- Do not modify test files to "improve" coverage.
- Do not add a missing bench target — flagging the absence is the finding.
- Do not run anything a second time to "get a cleaner number". One run is the data.
- Do not commit, push, branch, tag, or touch git state in any way.
- Do not invoke any bench command — bench dynamic execution does not exist in this skill version. PROF-1 stays static-only.

## Finding format

Exactly the format in `analyst-ground-rules.md`. Confidence = Verified only when a run actually produced the number you are quoting; static inference is Plausible at best.

## Severity scaling for COV-4 and COV-6

Both fire at tier-graded severity. Use this table without deviation:

| Finding | T1 | T2 | T3 |
|---------|----|----|----|
| COV-4 (no system)        | Low | Medium | High |
| COV-6 (below threshold)  | Low | Medium | High |
| COV-5 (undocumented)     | Low | Low | Low |

The synthesis right-sizing filter (`synthesis.md` §3) does not double-tier-filter these — they are already tier-aware. If a synthesis pass tries to drop a T1 COV-4 as "below tier threshold", that is a defect in synthesis, not in the analyst's emission.

## Checklist

You own:

{OWNED_CHECKLIST_ITEMS}

Use the five line shapes defined in `analyst-ground-rules.md`. Specifically:

- COV-4: emit `[x] <evidence: file:line of where the absence is "checkable"; e.g., package.json:1 — no `coverage` script, no `vitest`/`jest`/`pytest` config>` when filed; emit `[x] clean — coverage system present (<command>)` when a coverage command was detected. Never emit `[-] N/A` for COV-4 — the absence IS the finding.
- COV-5: emit `[x] <evidence: which docs were searched and what was found / not found>`; emit `[x] clean — threshold documented in <config|AGENTS.md|...>` when documented.
- COV-6: when dynamic pass succeeds, emit `[x] <evidence: current=<N>%, threshold=<M>%>`; when dynamic pass did not run (because COV-4 fired), emit `[?] inconclusive — no coverage system to measure against`.

## Output structure

Same structure as `analyst-ground-rules.md` "Output structure" — `## Coverage & Profiling Analyst` heading, then `### Findings`, `### Checklist`, `### Dropped at source`, `### Summary`, `### Self-check`. The Summary must explicitly state:

- whether the dynamic pass ran;
- which command was invoked and its provenance (`auto-detected:<cmd>` or `none-detected`);
- whether a threshold was found in coverage config or instruction files;
- the top one or two gaps.

If the detected command was absent, say what the project would need to add to make future runs possible — and acknowledge that COV-4 was filed.

## Calibration note

The threshold floors (T1 = 50%, T2 = 65%, T3 = 80%) and the `current − 5pp` clamp are starting points. The skill's `analysis-analysis.md` Part A retrospective is the place to record observations about whether these numbers fit real-world projects so a v-next author can retune.
```
```

(The outer Markdown file structure has the same shape as the existing peer file `coverage-profiling-prompt.md` had: file-level heading + meta-paragraph + outer fenced block holding the actual prompt-text-to-send.)

- [ ] **Step 3: Verify**

Run: `wc -l plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: ~95–105 lines (smaller than the current ~111 because the EXECUTION_CONSENT block is gone).

Run: `grep -c "EXECUTION_CONSENT\|DETECTED_BENCH_CMD\|granted\|declined" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: `0` (all consent / bench dynamic / granted / declined references removed).

Run: `grep -c "COV-4\|COV-5\|COV-6\|tier_floor\|max(tier_floor" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: ≥6 (each new ID appears at least once; the threshold formula appears at least once).

Run: `grep -c "no separate Step 3.5\|regular Step 3 parallel" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: `2` (one mention of each phrase in the file's intro).

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: rewrite coverage-profiling-prompt.md for v3.9

Drops EXECUTION_CONSENT branching, drops bench dynamic pass, adds
COV-4 (no system) / COV-5 (no documented threshold) / COV-6 (below
threshold) emission logic, adds threshold-documentation check across
AGENTS.md/CLAUDE.md/GEMINI.md/README.md plus coverage config, adds
the threshold derivation formula max(tier_floor, current-5pp) with
floors 50/65/80 for T1/T2/T3, and explicit severity-by-tier table
that synthesis right-sizing must NOT double-filter.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Update agent-roster.md

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`

Two edits: update Coverage row owned-IDs and scope; delete the entire `## Gated analyst: Coverage & Profiling` subsection.

- [ ] **Step 1: Update the Coverage row**

Edit. Find this exact line:

```
| **Coverage & Profiling Analyst** | Standard | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets | COV-1..COV-3, PROF-1..PROF-2 (new IDs — see coverage-profiling-prompt.md for definitions) |
```

Replace with:

```
| **Coverage & Profiling Analyst** | Standard | Test directories, coverage artifacts (`coverage/**`, `lcov.info`, `coverage-summary.json`), bench/profile artifacts (`bench/**`, `flamegraph.*`, `*.prof`), `package.json` scripts / `Makefile` / `justfile` / `Taskfile*` targets, instruction files (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `README.md`) for documented coverage thresholds | COV-1..COV-6, PROF-1..PROF-2 |
```

- [ ] **Step 2: Delete the "## Gated analyst: Coverage & Profiling" subsection**

Edit. Find this exact block (the subsection header + its single paragraph + the trailing blank line + the next section heading):

```
## Gated analyst: Coverage & Profiling

Unlike every other analyst, Coverage & Profiling may **run** project commands (coverage target, bench target). That breaks the read-only invariant of the rest of the skill, so it is gated behind the execution authorization captured at Step 0's single consolidated consent prompt — it does **not** dispatch in the Step 3 parallel fan-out. It is also static-capable: if the user chose `static-only` at Step 0, the analyst still produces a static gap-analysis pass (source→test mapping, missing-test inference, bench-target presence check) without running anything. Step 3.5 itself is non-interactive in v3.1+.

See `coverage-profiling-prompt.md` for the analyst's prompt; see SKILL.md Step 0 (preflight capture) and Step 3.5 (non-interactive dispatch) for the execution protocol.

## Escalation
```

Replace with (keep `## Escalation` heading; replace the deleted subsection with a slimmer inline note):

```
## Coverage & Profiling Analyst execution exception

Coverage & Profiling is the only analyst that may execute project commands. It runs the auto-detected coverage command unattended in the regular Step 3 parallel fan-out — there is no consent gate at dispatch time. The Step 0 confirmation prompt (proceed / abort / instruct) is the single point at which the user can prevent the run. If the orchestrator's Step 0 detection found no coverage command, the analyst files COV-4 *Missing test coverage tracking system* with tier-graded severity and runs the static pass only.

See `coverage-profiling-prompt.md` for the analyst's prompt and the threshold-derivation rule; see SKILL.md Step 0 for the preflight protocol and Step 3 for the dispatch list.

## Escalation
```

- [ ] **Step 3: Verify**

Run: `grep -c "COV-1..COV-6" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1` (the Coverage row's owned-IDs cell).

Run: `grep -c "## Gated analyst" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `0` (subsection deleted).

Run: `grep -c "## Coverage & Profiling Analyst execution exception" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1`.

Run: `grep -c "Step 3.5" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `0` (no remaining 3.5 references in this file).

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: roster — Coverage moves to Step 3 fan-out

Update Coverage & Profiling row: scope grows to include AGENTS.md /
CLAUDE.md / GEMINI.md / README.md (now read for documented coverage
thresholds); owned IDs grow to COV-1..COV-6. Replace the "Gated
analyst" subsection with a leaner "execution exception" note that
points at Step 0 as the single consent gate and at Step 3 as the
dispatch site. No more Step 3.5 references in this file.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Update analyst-ground-rules.md footnotes

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`

Two footnotes name "Step 3.5" and need rewording.

- [ ] **Step 1: Update the forbidden-commands footnote**

Edit. Find:

```
6. **Forbidden commands.** No `install`, `add`, `update`, `build`, `migrate`, `exec`, `test`, `run`, no package-manager subcommands that modify the project's state (lockfile, node_modules, virtualenvs, etc.), and no execution of project code or scripts. Allowed: `git log`, `git blame`, `git ls-files`, `git status`, `rg`, `ls`, `wc`, and the Read tool. (The Coverage & Profiling analyst has an explicit exception in Step 3.5; no other analyst does.)
```

Replace with:

```
6. **Forbidden commands.** No `install`, `add`, `update`, `build`, `migrate`, `exec`, `test`, `run`, no package-manager subcommands that modify the project's state (lockfile, node_modules, virtualenvs, etc.), and no execution of project code or scripts. Allowed: `git log`, `git blame`, `git ls-files`, `git status`, `rg`, `ls`, `wc`, and the Read tool. (The Coverage & Profiling analyst has an explicit exception described in its own prompt — it may invoke a single auto-detected coverage command unattended; no other analyst may execute anything.)
```

- [ ] **Step 2: Update the dependency-freshness allowlist footnote**

In the same file, find:

```
   (The Coverage & Profiling analyst has a separate, broader exception in Step 3.5; the allowlist above is for all analysts, not just Coverage.)
```

Replace with:

```
   (The Coverage & Profiling analyst has a separate, broader exception described in its own prompt; the allowlist above is for all analysts, not just Coverage.)
```

- [ ] **Step 3: Verify**

Run: `grep -c "Step 3.5" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`
Expected: `0`.

Run: `grep -c "no other analyst may execute anything\|exception described in its own prompt" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md`
Expected: `2` (one match each).

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/analyst-ground-rules.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: drop Step 3.5 references from ground rules

Two footnotes (forbidden-commands rule, dependency-freshness allowlist
note) named Step 3.5 as the home of the Coverage analyst's execution
exception. Step 3.5 no longer exists; the exception now lives in the
Coverage analyst's own prompt. Wording updated to point readers there.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Strip residual EXECUTION_MODE references from synthesis.md

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`

Synthesis doesn't drive coverage decisions but may carry stale references to `EXECUTION_MODE`, `static-only`, or `execution declined`. This task searches and rewrites any that exist.

- [ ] **Step 1: Find any residual references**

Run: `grep -n "EXECUTION_MODE\|EXECUTION_CONSENT\|static-only\|execution declined\|Step 3.5" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`

Capture the output. Two outcomes:

- **No matches:** synthesis.md is already clean. Skip Steps 2 and 3, go straight to Step 4 (commit nothing — there is no edit to commit).
- **One or more matches:** for each match, decide whether the surrounding sentence still makes sense after removing or rewording. Most likely the matches are inside a §3 right-sizing filter footnote about coverage findings.

- [ ] **Step 2: Apply rewrites if needed**

For each match found in Step 1, edit the file as follows:

- A reference to `EXECUTION_MODE = static-only` → rewrite as "no coverage system detected (COV-4 was filed)".
- A reference to "static-only pass" in the context of Coverage → rewrite as "the static pass" (Coverage analyst always runs both static + dynamic in v3.9; "static pass" is just the part that doesn't need a command).
- A reference to "Step 3.5" → rewrite as "Step 3 (the parallel-dispatch fan-out)".
- Direct reference to `EXECUTION_CONSENT` → delete the sentence; the variable does not exist anymore.

If your edit makes a paragraph nonsensical, rewrite the paragraph to convey the same intent in the new model. The synthesis pipeline itself does not change — coverage findings still flow through §1–§13 the same way.

- [ ] **Step 3: Verify**

Run: `grep -c "EXECUTION_MODE\|EXECUTION_CONSENT\|static-only\|execution declined\|Step 3.5" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md`
Expected: `0`.

- [ ] **Step 4: Commit (only if Step 2 produced changes)**

If Step 1 reported "no matches", skip this commit entirely — there is nothing to commit.

If Step 2 produced changes:

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/synthesis.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: synthesis docs drop Step 3.5 references

Stale references to EXECUTION_MODE, static-only, and Step 3.5
removed or rewritten. Synthesis pipeline itself is unchanged;
coverage findings still flow through §1–§13 the same way.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Reshape Step 0 in SKILL.md

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`

Rewrite the entire `## Step 0 — Preflight` section (lines ~65–107) to drop bench detection, drop the 5-option execution-mode picker, and add the proceed/abort/instruct prompt with free-text directive protocol.

- [ ] **Step 1: Locate the Step 0 section**

Run: `grep -n "^## Step 0\|^## Step 1" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: two matches; Step 0 starts ~line 65, Step 1 starts ~line 109.

- [ ] **Step 2: Replace the Step 0 section**

Edit. Find this exact block (the entire `## Step 0 — Preflight` section through its 8 numbered items, ending at the blank line before `## Step 1 — Structure Scout`):

```
## Step 0 — Preflight

**Design rule: Step 0 is the only step that may prompt the user.** Every decision the run will need (proceed, dynamic-execution mode, command overrides) is captured here in a single consolidated prompt so the rest of the run — Steps 1 through 6 — can execute unattended. A user should be able to kick off this skill before going to bed and wake up to a finished report.

1. **Capture the skill's own revision up-front** (see Step 6 for the fallback chain). Keep the value in the orchestrator's working memory so it lands in `analysis-analysis.md` even if the skill repo becomes unavailable partway through.

2. **Load deferred tools.** `AskUserQuestion`, `TaskCreate`, and `TaskUpdate` may be deferred tools in your harness (visible by name in a `<system-reminder>` but not callable until their schemas load). If a tool call fails with `InputValidationError`, run `ToolSearch` with `select:AskUserQuestion,TaskCreate,TaskUpdate` first, then retry. This is cheap and saves a round-trip at the consent prompt.

3. **Detect coverage and bench commands now** (no Scout required for this). Read, in order of preference: `package.json` scripts (keys matching `cov`, `coverage`, `bench`, `benchmark`, `profile`), top-level `Makefile`, `justfile`, `Taskfile*`, `pyproject.toml` `[tool.*.scripts]` equivalents. Record the most-specific match per category. Possible outcomes per category:
   - `auto-detected:<cmd>` — exactly one plausible command found (e.g., `bun run coverage:check`).
   - `auto-detected:<cmd> (+ N alternatives)` — multiple plausible commands found; pick the most-specific but list the alternatives in the prompt.
   - `none-detected` — no candidate.

4. **Single consolidated consent prompt.** Issue **one** `AskUserQuestion` call that captures every decision the run will need. The prompt must include:

   - The token warning: *"This run dispatches several analyst subagents in parallel and will consume a large number of tokens. It is best run when weekly quota has spare headroom."*
   - The detected coverage command and bench command (or `none-detected` for either/both).
   - A choice of execution mode:
     - `Run both dynamic passes (coverage + bench)`
     - `Run coverage only`
     - `Run bench only`
     - `Static-only — no project commands run`
     - `Let me correct the detected commands first`
     - `Abort`
   - A note: *"After you answer this prompt, the rest of the run will proceed unattended through Steps 1 – 6. No further user interaction is required."*

   If the user picks `Let me correct the detected commands first`, issue a **second** `AskUserQuestion` with free-text slots for each command, then re-issue the primary prompt with the user-corrected values (provenance `user-corrected:<cmd>`) so the user confirms the mode choice with the corrected commands in view. Maximum two round-trips — after that, accept whatever the user last picked.

   If the user does not answer within a reasonable window, or picks `Abort`, emit a short status message and stop. Never block indefinitely.

5. **Record the preflight decision** in the orchestrator's working memory for the rest of the run:
   ```
   EXECUTION_MODE       = both | coverage-only | bench-only | static-only
   COVERAGE_CMD         = auto-detected:<cmd> | user-corrected:<cmd> | none-detected
   BENCH_CMD            = auto-detected:<cmd> | user-corrected:<cmd> | none-detected
   ```
   Step 3.5 consumes these values non-interactively.

6. **Check git state, but do not gate on it.** Run `git status --porcelain`. If output is non-empty, note in Run metadata that any `file:line` references in the resulting report may shift if the tree is committed or reverted afterward. Do **not** prompt the user — a dirty tree is not a safety issue and the user has already authorized the run.

7. **Pick a non-clobbering report directory.** Default: `docs/code-analysis/YYYY-MM-DD/`. If that directory already exists, use `YYYY-MM-DD-HHMMSS/` instead. Never overwrite a prior report directory.

8. **Create the directory skeleton,** empty. Include `.scratch/` always; include `clusters/` and `by-analyst/` only if you already know you'll render in full multi-file mode (otherwise wait until Step 5, when synthesis's finding count reveals the rendering mode). The `scripts/` subdirectory is created at Step 5 rendering time with `render-status.sh` copied in.
```

Replace with this exact block:

```
## Step 0 — Preflight

**Design rule: Step 0 is the only step that may prompt the user.** A single confirmation gate at the start lets the user proceed, abort, or issue free-text instructions/questions. After that, the rest of the run — Steps 1 through 6 — executes unattended. A user should be able to kick off this skill before going to bed and wake up to a finished report.

1. **Capture the skill's own revision up-front** (see Step 6 for the fallback chain). Keep the value in the orchestrator's working memory so it lands in `analysis-analysis.md` even if the skill repo becomes unavailable partway through.

2. **Load deferred tools.** `AskUserQuestion`, `TaskCreate`, and `TaskUpdate` may be deferred tools in your harness (visible by name in a `<system-reminder>` but not callable until their schemas load). If a tool call fails with `InputValidationError`, run `ToolSearch` with `select:AskUserQuestion,TaskCreate,TaskUpdate` first, then retry. This is cheap and saves a round-trip at the consent prompt.

3. **Detect the coverage command now** (no Scout required for this). Read, in order of preference: `package.json` scripts (keys matching `cov`, `coverage`), top-level `Makefile`, `justfile`, `Taskfile*`, `pyproject.toml` `[tool.*.scripts]` equivalents. Record the most-specific match. Outcomes:
   - `auto-detected:<cmd>` — exactly one plausible command found (e.g., `bun run coverage:check`).
   - `auto-detected:<cmd> (+ N alternatives)` — multiple candidates; pick the most-specific.
   - `none-detected` — no candidate.

   Bench command detection is no longer performed in this version. PROF-1 (missing bench target where PERF findings exist) and PROF-2 (stale bench artifacts) remain as static-only checks owned by the Coverage & Profiling analyst.

4. **Confirmation prompt with free-text slot.** Issue **one** `AskUserQuestion` call. The prompt body includes:

   - The token warning: *"This run dispatches several analyst subagents in parallel and will consume a large number of tokens. It is best run when weekly quota has spare headroom."*
   - The detected coverage command (or `none-detected — COV-4 will be filed`) and a one-line note: *"Coverage will run automatically if a tracking system is detected. To skip, type that into the instructions slot."*
   - Three options:
     - **Proceed** — start the run as detected.
     - **Abort** — exit, no work done.
     - **Instructions / questions** — free-text slot. The user types directives or questions; the orchestrator interprets and applies, then re-prompts proceed / abort.
   - A note: *"After you proceed, the rest of the run will execute unattended through Steps 1 – 6. No further user interaction is required."*

   **Free-text directive protocol:**

   When the user picks the free-text option:
   1. Capture the user's text verbatim.
   2. Classify as **question** (interrogative form, no imperative directive), **directive** (imperative form), or **mixed**.
   3. For questions: answer concisely (≤200 words) using only information already in scope (codebase map will be available after Scout, but at Step 0 use only the manifest, package.json, and detected commands). Re-prompt: proceed / abort / more.
   4. For directives: parse against the closed directive vocabulary below. Record the directive in `RUN_DIRECTIVES` (orchestrator working memory). Re-prompt: proceed / abort.
   5. Round-trip cap = 2. After two free-text iterations, the third re-prompt offers only proceed / abort (no more free-text slot). Prevents runaway loops.

   **Closed directive vocabulary (v3.9):**
   - `skip <analyst-name>` — drop that analyst from the Step 3 dispatch list. Recorded in Run metadata as `Analyst override: skipped <analyst> per user request`.
   - `use senior on <analyst-name>` — model-tier override; recorded in Run metadata as `Analyst override: per user request, <analyst> ran on senior`.
   - `ignore <path-or-glob>` — exclude from all analysts' scope (passed as an additional negative glob in `{SCOPE_GLOBS}`). Recorded in Run metadata as `Scope override: ignoring <glob> per user request`.
   - `set tier T<N>` (where N ∈ {1, 2, 3}) — override Scout's tier classification. Recorded in Run metadata as `Tier override: set to T<N> per user request, Scout's classification ignored`.

   Anything outside this vocabulary: orchestrator declines and re-prompts (*"That directive isn't supported in this run; proceed / abort / try a question?"*). The orchestrator does not invent directive shapes.

   If the user does not answer within a reasonable window, or picks `Abort`, emit a short status message and stop. Never block indefinitely.

5. **Record the preflight decision** in the orchestrator's working memory for the rest of the run:
   ```
   COVERAGE_CMD     = auto-detected:<cmd> | none-detected
   RUN_DIRECTIVES   = list of accepted directives (may be empty)
   ```

   Step 3 dispatch consumes `COVERAGE_CMD` (passed as `{DETECTED_COVERAGE_CMD}` to the Coverage & Profiling analyst) and applies `RUN_DIRECTIVES` to the dispatch list / scope globs / tier as appropriate.

6. **Check git state, but do not gate on it.** Run `git status --porcelain`. If output is non-empty, note in Run metadata that any `file:line` references in the resulting report may shift if the tree is committed or reverted afterward. Do **not** prompt the user — a dirty tree is not a safety issue and the user has already authorized the run.

7. **Pick a non-clobbering report directory.** Default: `docs/code-analysis/YYYY-MM-DD/`. If that directory already exists, use `YYYY-MM-DD-HHMMSS/` instead. Never overwrite a prior report directory.

8. **Create the directory skeleton,** empty. Include `.scratch/` always; include `clusters/` and `by-analyst/` only if you already know you'll render in full multi-file mode (otherwise wait until Step 5, when synthesis's finding count reveals the rendering mode). The `scripts/` subdirectory is created at Step 5 rendering time with `render-status.sh` copied in.
```

- [ ] **Step 3: Verify**

Run: `grep -c "EXECUTION_MODE\|BENCH_CMD" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `0` for `EXECUTION_MODE`; `0` for `BENCH_CMD` (the variable name no longer appears anywhere in SKILL.md). Total = `0`.

Run: `grep -c "RUN_DIRECTIVES\|Closed directive vocabulary\|Free-text directive protocol" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `3` (one match each).

Run: `grep -n "^## Step 0\|^## Step 1" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: two matches (the Step 0 and Step 1 headings, with Step 0 starting around line 65 and Step 1 a bit further down than before — the new Step 0 is roughly the same length as the old).

- [ ] **Step 4: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: Step 0 reshape — proceed/abort/instruct

Drop the 5-option execution-mode picker, drop bench detection, drop
EXECUTION_MODE / BENCH_CMD variables. Step 0 issues a single
AskUserQuestion with three options: proceed / abort / free-text
instructions-or-questions. Free-text slot accepts a closed directive
vocabulary (skip <analyst>, use senior on <analyst>, ignore <glob>,
set tier T<N>) plus arbitrary questions; 2-round-trip cap. RUN_DIRECTIVES
captured for Step 3 dispatch.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Delete Step 3.5 + update graph + clean cross-references

**Files:**
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`

Three changes in this task: delete the entire Step 3.5 section, update the execution-flow graph to remove the Step 3.5 node, and clean three other places that name Step 3.5 (References table, Step 3 dispatch list, Common mistakes).

- [ ] **Step 1: Update the execution-flow graph**

Edit. Find:

```
    "Step 0 — Preflight" [shape=box];
    "Step 1 — Structure Scout (maps + tiers + drift)" [shape=box];
    "Step 2 — Scope resolution (prune by applicability + tier)" [shape=box];
    "Step 3 — Dispatch analysts (parallel, read-only)" [shape=box];
    "Step 3.5 — Coverage & Profiling (gated)" [shape=box];
    "Step 4 — Synthesis: dedup + right-size + cluster" [shape=box];
```

Replace with:

```
    "Step 0 — Preflight" [shape=box];
    "Step 1 — Structure Scout (maps + tiers + drift)" [shape=box];
    "Step 2 — Scope resolution (prune by applicability + tier)" [shape=box];
    "Step 3 — Dispatch analysts (parallel, incl. Coverage & Profiling)" [shape=box];
    "Step 4 — Synthesis: dedup + right-size + cluster" [shape=box];
```

Then find:

```
    "Step 2 — Scope resolution (prune by applicability + tier)" -> "Step 3 — Dispatch analysts (parallel, read-only)";
    "Step 3 — Dispatch analysts (parallel, read-only)" -> "Step 3.5 — Coverage & Profiling (gated)";
    "Step 3.5 — Coverage & Profiling (gated)" -> "Step 4 — Synthesis: dedup + right-size + cluster";
```

Replace with:

```
    "Step 2 — Scope resolution (prune by applicability + tier)" -> "Step 3 — Dispatch analysts (parallel, incl. Coverage & Profiling)";
    "Step 3 — Dispatch analysts (parallel, incl. Coverage & Profiling)" -> "Step 4 — Synthesis: dedup + right-size + cluster";
```

- [ ] **Step 2: Update the References table entries**

Edit. Find:

```
| `references/agent-roster.md` | Which analysts exist, what they own, when they run (including the gated Coverage & Profiling analyst); `scripts/` ownership rules |
```

Replace with:

```
| `references/agent-roster.md` | Which analysts exist, what they own, when they run; `scripts/` ownership rules; the Coverage & Profiling Analyst execution-exception note |
```

Then find:

```
| `references/coverage-profiling-prompt.md` | Prompt for the Step 3.5 gated analyst; consumes the Step 0 consolidated preflight decision (no mid-run prompts) |
```

Replace with:

```
| `references/coverage-profiling-prompt.md` | Prompt for the Coverage & Profiling Analyst (dispatched in Step 3 alongside the other analysts); contains the only execution exception in the skill, the threshold-derivation rule for COV-6, and the COV-4 / COV-5 emission logic |
```

- [ ] **Step 3: Update the read-only-exception sentence in the Overview**

Edit. Find:

```
**The only writes permitted are to `docs/code-analysis/`** (the report directory and a scratch subdirectory). No code modifications. Read-only shell commands only, with **one carefully-bounded exception**: Step 3.5 may invoke the project's own existing coverage and bench commands — but only if the user authorized dynamic execution at Step 0's single consolidated consent prompt. Never run builds, migrations, installs, or any other subcommand that mutates state.
```

Replace with:

```
**The only writes permitted are to `docs/code-analysis/`** (the report directory and a scratch subdirectory). No code modifications. Read-only shell commands only, with **one carefully-bounded exception**: the Coverage & Profiling Analyst may invoke the project's own auto-detected coverage command — once, with a 15-minute timeout. Bench commands are no longer executed (PROF-1 / PROF-2 stay as static checks). Never run builds, migrations, installs, or any other subcommand that mutates state.
```

- [ ] **Step 4: Delete the entire Step 3.5 section**

Edit. Find this exact block (the entire `## Step 3.5` section through its 2 numbered items, ending at the blank line before `## Step 4 — Synthesis`):

```
## Step 3.5 — Coverage & Profiling (non-interactive)

This step consumes the preflight decision from Step 0 — no prompting happens here. If a run started unattended, it stays unattended.

Map Step 0's `EXECUTION_MODE` to analyst dispatch:

| `EXECUTION_MODE` | Dispatch | `{EXECUTION_CONSENT}` |
|------------------|----------|------------------------|
| `both` | Dispatch Coverage & Profiling with both commands live | `granted` |
| `coverage-only` | Dispatch, but pass `BENCH_CMD = none-detected` so bench pass is skipped | `granted` |
| `bench-only` | Dispatch, but pass `COVERAGE_CMD = none-detected` so coverage pass is skipped | `granted` |
| `static-only` | Dispatch with both commands passed as captured, but `{EXECUTION_CONSENT} = declined` | `declined` |

1. **Dispatch the Coverage & Profiling analyst** with the prompt in `references/coverage-profiling-prompt.md`. Substitutions: `{EXECUTION_CONSENT}`, `{DETECTED_COVERAGE_CMD}`, `{DETECTED_BENCH_CMD}` all come from the Step 0 preflight capture. The analyst is the single choke point for runtime invocation; the orchestrator does not run anything itself.

   **Timeout requirement.** When the Coverage & Profiling analyst invokes Bash to run `{DETECTED_COVERAGE_CMD}` or `{DETECTED_BENCH_CMD}`, it must pass `timeout: 900000` (15 minutes) explicitly. Real-world coverage suites routinely run 5–12 minutes; the harness's default 2-minute Bash timeout will kill them mid-run. The orchestrator surfaces this requirement in the analyst's prompt (see `references/coverage-profiling-prompt.md`). If the user's preflight included a longer per-gate timeout override, use that; otherwise 900000 is the floor for this analyst.

2. **Merge output into synthesis.** The analyst's findings and checklist lines flow through Step 4 the same way as every other analyst — the only novelty is the optional dynamic-pass Confidence upgrade from Plausible to Verified on covered items.

If the user chose `Abort` at Step 0, this step is never reached. There is no separate "skip" mode in v3.1+ — `static-only` is the zero-execution path, and it still dispatches the analyst (which runs its full static pass). Record `Coverage & Profiling: static-only` or the relevant mode in Run metadata.

## Step 4 — Synthesis
```

Replace with (Step 3.5 deleted; Step 4 heading retained):

```
## Step 4 — Synthesis
```

- [ ] **Step 5: Update the Step 3 dispatch instructions to mention Coverage explicitly**

Edit. Find this exact block (the Step 3 opening paragraph plus its substitutions list):

```
## Step 3 — Dispatch analysts (parallel)

Launch all remaining analysts **in a single message** using multiple `Agent` tool calls so they run concurrently. Each agent is an Explore subagent. Each prompt is assembled from `references/agent-prompt-template.md` (the wrapper) with these substitutions:
```

Replace with:

```
## Step 3 — Dispatch analysts (parallel)

Launch all remaining analysts **in a single message** using multiple `Agent` tool calls so they run concurrently. The Coverage & Profiling Analyst dispatches in this same message — it has no separate Step 3.5; the only thing distinguishing it is that it may invoke the auto-detected coverage command, which is documented in its own prompt. Each agent is an Explore subagent. Each prompt is assembled from `references/agent-prompt-template.md` (the wrapper) with these substitutions:
```

Then find this Step 3 substitutions list closing line:

```
- `{APPLICABILITY_FLAGS}` — Scout's applicability flags block (including sub-flags like `web-facing-ui: present, auth-gated`). Analysts key default N/A behaviors off these.
```

Replace with (a Coverage-specific substitution added):

```
- `{APPLICABILITY_FLAGS}` — Scout's applicability flags block (including sub-flags like `web-facing-ui: present, auth-gated`). Analysts key default N/A behaviors off these.
- `{DETECTED_COVERAGE_CMD}` — the Coverage & Profiling Analyst gets this additional substitution from the Step 0 preflight capture. Pass `auto-detected:<cmd>` if a coverage command was detected; pass `none-detected` if none was found (the analyst will file COV-4 in that case). Other analysts do not receive this substitution.
```

- [ ] **Step 6: Update Common mistakes entries**

Edit. Find:

```
- **Asking a second consent before Step 3.5.** Step 3.5 is non-interactive in v3.1+. The dynamic-execution authorization lives in the Step 0 `EXECUTION_MODE` value. If you find yourself wanting to re-ask, stop — the user explicitly designed this skill to run overnight.
```

Replace with:

```
- **Asking a second consent for the Coverage analyst's command execution.** Coverage runs unattended in Step 3 if a command was auto-detected at Step 0. The user's last opportunity to abort is the Step 0 confirmation prompt; do not re-ask in Step 3 or Step 4.
```

Then find:

```
- **Running anything outside Step 3.5.** No `bun test`, no `npm run build`, no migrations, no scripts in any other step. Static reading only.
```

Replace with:

```
- **Running anything outside the Coverage & Profiling Analyst.** No `bun test`, no `npm run build`, no migrations, no scripts run by any other analyst — and no bench commands run by anyone in v3.9+. The Coverage & Profiling Analyst is the single execution exception. Static reading only for everyone else.
```

- [ ] **Step 7: Verify**

Run: `grep -c "Step 3.5\|EXECUTION_MODE\|EXECUTION_CONSENT\|BENCH_CMD\|DETECTED_BENCH_CMD" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `0`.

Run: `grep -c "DETECTED_COVERAGE_CMD" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `1` (one mention in the Step 3 substitutions list).

Run: `grep -n "^## Step " plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: 7 lines for Steps 0, 1, 2, 3, 4, 5, 6 (no Step 3.5).

Run: `grep -c "Step 3.5 — Coverage" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `0`.

- [ ] **Step 8: Commit**

```bash
git add plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: delete Step 3.5, fold Coverage into Step 3

Execution-flow graph drops the Step 3.5 node. Step 3 dispatch list
now mentions Coverage & Profiling as a regular analyst with a single
extra substitution ({DETECTED_COVERAGE_CMD}). Step 3.5 section
deleted wholesale. References table updated. Read-only-exception
sentence in Overview rewritten. Two Common-mistakes entries pointing
at Step 3.5 rewritten to point at the Coverage Analyst instead.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Bump versions to 3.9.0

**Files:**
- Modify: `plugins/codebase-deep-analysis/.claude-plugin/plugin.json`
- Modify: `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION`
- Modify: `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION`

`scripts/test-version-metadata.sh` requires all three to match.

- [ ] **Step 1: Update plugin.json**

Edit. In `plugins/codebase-deep-analysis/.claude-plugin/plugin.json`, replace:

```
  "version": "3.8.0",
```

with:

```
  "version": "3.9.0",
```

- [ ] **Step 2: Update codebase-deep-analysis VERSION**

Read the file first (Write requires it). Then Write `plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION` with exact content (one line + trailing newline):

```
3.9.0
```

- [ ] **Step 3: Update implement-analysis-report VERSION**

Read the file first. Then Write `plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION` with exact content:

```
3.9.0
```

- [ ] **Step 4: Run the validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected stdout: `codebase-deep-analysis plugin and bundled skill versions ok: 3.9.0`
Expected exit code: `0`.

- [ ] **Step 5: Commit**

```bash
git add plugins/codebase-deep-analysis/.claude-plugin/plugin.json plugins/codebase-deep-analysis/skills/codebase-deep-analysis/VERSION plugins/codebase-deep-analysis/skills/implement-analysis-report/VERSION
git commit -m "$(cat <<'EOF'
codebase-deep-analysis: bump to 3.9.0 (Step 3.5 redesign)

Eliminates Step 3.5; Coverage & Profiling Analyst dispatches in
Step 3 with no consent gate. Step 0 simplified to proceed/abort/
instruct with a closed-vocabulary free-text directive slot. Adds
COV-4 (no coverage system, T1 Low / T2 Medium / T3 High), COV-5
(undocumented threshold, Low everywhere), and COV-6 (current below
documented or derived threshold, T1 Low / T2 Medium / T3 High).
Bench dynamic execution dropped (PROF-1 / PROF-2 remain static).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Final verification

**Files:** none (read-only checks).

Final sanity sweep before declaring done. No edits, no commit.

- [ ] **Step 1: Re-run the version validator**

Run: `bash plugins/codebase-deep-analysis/scripts/test-version-metadata.sh`
Expected: `codebase-deep-analysis plugin and bundled skill versions ok: 3.9.0`, exit code 0.

- [ ] **Step 2: Confirm Step 3.5 is gone everywhere**

Run: `grep -rn "Step 3.5\|EXECUTION_MODE\|EXECUTION_CONSENT\|BENCH_CMD\|DETECTED_BENCH_CMD" plugins/codebase-deep-analysis/`
Expected: empty output (no matches in any file under the plugin).

- [ ] **Step 3: Confirm new IDs landed**

Run: `grep -c "^| COV-" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/checklist.md`
Expected: `6`.

Run: `grep -c "COV-1..COV-6" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/agent-roster.md`
Expected: `1`.

Run: `grep -c "COV-4\|COV-5\|COV-6" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/references/coverage-profiling-prompt.md`
Expected: ≥6.

- [ ] **Step 4: Confirm Step 0 reshape landed**

Run: `grep -c "RUN_DIRECTIVES\|Closed directive vocabulary\|Free-text directive protocol\|set tier T<N>" plugins/codebase-deep-analysis/skills/codebase-deep-analysis/SKILL.md`
Expected: `4`.

- [ ] **Step 5: Verify commit log**

Run: `git log --oneline -12`
Expected: 7 or 8 new commits on top of the spec commit (Task 5 may have produced no commit if synthesis.md had no stale references), in this rough order (most recent first):

1. version bump to 3.9.0 (Task 8)
2. Step 3.5 deletion + cross-ref cleanup (Task 7)
3. Step 0 reshape (Task 6)
4. (optional) synthesis.md cleanup (Task 5)
5. analyst-ground-rules.md footnote rewrites (Task 4)
6. agent-roster.md update (Task 3)
7. coverage-profiling-prompt.md rewrite (Task 2)
8. checklist.md COV-4..COV-6 (Task 1)

If the actual log is missing a commit unexpectedly, do NOT amend — note the discrepancy in the final report. The validator pass + the spot-check greps are the load-bearing acceptance gates.

- [ ] **Step 6: Optional manual smoke test**

Run the codebase-deep-analysis skill on a real project to confirm:

- The Step 0 prompt offers proceed / abort / free-text instructions.
- A free-text directive like `skip Coverage Analyst` is accepted and recorded in Run metadata.
- If the project has no coverage tracking, the run completes and the report contains a COV-4 finding with severity matching the tier (Low for T1, Medium for T2, High for T3).
- If the project has coverage tracking but no documented threshold, the report contains a COV-5 finding (Low at all tiers).

Do NOT make this a blocker for declaring the change complete. The static plan completion (Tasks 1–8) is the merge gate. If the smoke run reveals a mismatch, file an issue and iterate.

---

## Self-Review

**Spec coverage:**

| Spec section | Plan task |
|--------------|-----------|
| Step 0 reshape (drop EXECUTION_MODE, drop bench detection, slim consent prompt) | Task 6 |
| Free-text directive protocol (closed vocabulary, 2-round-trip cap) | Task 6 |
| Step 3.5 elimination (delete section, update graph) | Task 7 |
| Step 3 dispatch list update to include Coverage | Task 7 Step 5 |
| Coverage & Profiling Analyst behavior changes (drop EXECUTION_CONSENT, drop bench dynamic, add COV-4/5/6 logic, threshold derivation, AGENTS.md doc-target instruction) | Task 2 |
| New checklist IDs COV-4 / COV-5 / COV-6 with severity-by-tier | Task 1 |
| Severity mapping (T1=Low / T2=Medium / T3=High for COV-4 and COV-6; Low everywhere for COV-5) | Task 1 (rows) + Task 2 (analyst severity table) |
| Coverage analyst roster row update + delete "Gated analyst" subsection | Task 3 |
| Synthesis docs strip residual EXECUTION_MODE refs | Task 5 (no-op if no matches) |
| analyst-ground-rules.md footnote rewrites | Task 4 |
| structure-scout-prompt.md no change | Implicit — no plan task; spec confirms no change |
| agent-prompt-template.md no change | Implicit — no plan task; spec confirms no change |
| Version bump 3.8.0 → 3.9.0 | Task 8 |
| Calibration note in coverage-profiling-prompt.md | Task 2 (last paragraph in the prompt body) |

All spec sections covered. Risks and out-of-scope sections are commentary, not implementation requirements.

**Placeholder scan:** None. All commands runnable, all expected outputs stated, all file replacements show exact content. The "if no matches in synthesis.md" branch in Task 5 is a real branch (not a placeholder) — the engineer is told what to do in either case.

**Type consistency:** No types in this plan (documentation editing). Variable / placeholder names used:
- `COVERAGE_CMD` — used consistently in Tasks 6 (Step 0 record) and Task 7 (Step 3 substitution).
- `DETECTED_COVERAGE_CMD` — used consistently in Task 2 (analyst prompt) and Task 7 (Step 3 substitution).
- `RUN_DIRECTIVES` — used only in Task 6 Step 0 record and Step 3 dispatch reference.
- `tier_floor` — used in Task 1 (COV-6 description) and Task 2 (analyst threshold derivation).
- COV-4 / COV-5 / COV-6 — consistent across Tasks 1, 2, 3, 9.
- Severity table (T1=Low, T2=Medium, T3=High for COV-4/COV-6; Low everywhere for COV-5) — consistent across Tasks 1, 2.

No drift detected.
