# Preflight prompt (Step 0)

The whole interaction with the user lives in this single step. One `AskUserQuestion` with every decision the run needs. At most one follow-up if the user picks `edit detected commands / gates first`. After that, Steps 1–5 proceed unattended.

## Data the orchestrator must collect before issuing the prompt

Gather these before the user sees anything — the prompt itself shows summarized values, not interactive detection.

1. **Report directory.** Either passed as the skill's argument or defaulted to the newest `docs/code-analysis/*/` directory. Verify it exists and contains a recognizable layout (`README.md` + `clusters/` dir, `REPORT.md` with `<!-- cluster:NN:start -->` markers, or `README.md` + no clusters — fail cleanly if none).
2. **cda version compatibility.** Read `{report-dir}/.scratch/codebase-map.md` first line or look for the v3+ frontmatter fields in any cluster (`Autonomy:`, `informally-unblocks:`). Abort with a clear message if the report predates v3.0.
3. **Dependencies installed.** Probe the harness for `superpowers:subagent-driven-development`. If not discoverable, abort before any user interaction.
4. **Cluster enumeration.** Walk every cluster (full-multi-file: `clusters/*.md`; compact-multi-file: same; single-file: parse `<!-- cluster:NN:start -->` / `<!-- cluster:NN:end -->` blocks from `REPORT.md`). For each cluster collect: slug, goal, **Status**, Autonomy, Depends-on, informally-unblocks, Pre-conditions, per-cluster `gate:` override (if any), needs-decision question (from Suggested session approach block). Also partition the collected list into two groups:
   - **Active**: `Status` ∈ {`open`, `in-progress`}. Eligible for the default `all` subset.
   - **Terminal**: `Status` ∈ {`closed`, `partial`, `deferred`, `resolved-by-dep`}. Excluded from the default `all` subset; only processed if the user sets `include-terminal: true`.
5. **Gate detection.** Read `package.json` scripts, top-level `Makefile`, `justfile`, `Taskfile*`, `pyproject.toml` `[tool.*.scripts]`. Build the baseline set per `gate-detection.md` rules.
6. **Test-directory classification.** Read the project's typecheck config (`tsconfig.check.json`, `tsconfig.test.json`, `tsconfig.json`) and/or test runner config (`jest.config.*` `testPathIgnorePatterns`, `pytest.ini` `testpaths`, `vitest.config.*` `test.include`, etc.). For each test directory discovered in the project, classify:
   - `tsc-checked: true` — directory is included in the typecheck config's `include` pattern
   - `tsc-checked: false` — excluded, or no typecheck config exists at all
   - Also note any framework-specific constraint (e.g., "tests/api/** imports +server.ts and pulls Locals.ctx types from SvelteKit routes into scope").

   Build a `TEST_DIR_CLASSIFICATION` map:

   ```
   TEST_DIR_CLASSIFICATION = {
     "tests/unit": {"tsc_checked": true, "notes": ""},
     "tests/api":  {"tsc_checked": false, "notes": "imports +server.ts; Locals.ctx typing requires widened tsconfig"},
     "tests/e2e":  {"tsc_checked": false, "notes": "Playwright runner; not typechecked"}
   }
   ```

   This is read by Step 2's cluster subagent via `{TEST_DIR_CLASSIFICATION}` so subagents placing new tests pick the right destination without asking.

7. **Current branch and working-tree state.** `git rev-parse --abbrev-ref HEAD`, `git status --porcelain`. Needed to surface warnings in the prompt (uncommitted changes + non-current-branch strategy = warning; uncommitted changes + current-branch strategy = warning; clean tree = no warning).

## Prompt structure

Issue exactly one `AskUserQuestion` with these sections:

```
Implement Analysis Report

Report: {report-dir}  (cda v{version}, {N} clusters)

== CLUSTER SUBSET ==
All active clusters (default)
  [will process {N_active} open / in-progress clusters in topological Depends-on order]
  [{N_terminal} terminal-state clusters (closed / partial / deferred / resolved-by-dep)
   are skipped — set `include-terminal: true` to re-attempt them]
Only specific clusters
  [user lists slugs; the rest stay untouched; terminal-state slugs in the list
   warn and require `include-terminal: true` to proceed]
All except specific clusters
  [user lists active slugs to skip; the remaining active set proceeds]

Re-attempt terminal-state clusters? ( ) No (default)  ( ) Yes — include-terminal: true
  [Use on a resumption run when you want to re-verify already-closed clusters
   against current code (drift check) or retry a deferred cluster. Only the
   clusters you explicitly include are attempted; their Status remains whatever
   it was until the re-attempt commits or defers again.]

== DECISIONS (needs-decision clusters in subset) ==
For each needs-decision cluster in the subset, show a question derived
from its Suggested session approach block, accept free-text answer:

  Cluster 04-auth-rewrite — [question from cluster body]
    Your answer: _____________
  Cluster 11-slider-refactor — [question from cluster body]
    Your answer: _____________
  ...

== NEEDS-SPEC HANDLING ==
For each needs-spec cluster in the subset:

  Cluster 02-webgl-harness — [default: auto-defer to docs/ideas/02-webgl-harness.md]
    Alternative: answer now with a free-text spec

== BRANCH STRATEGY ==
( ) New branch `fix/deep-analysis-{YYYY-MM-DD}`  (default)
( ) Current branch `{current-branch}`
( ) Git worktree (isolated; requires superpowers:using-git-worktrees)

== VERIFICATION GATES (auto-detected) ==
test:     `{detected-test-cmd}`    [edit] [remove]
typecheck: `{detected-tc-cmd}`     [edit] [remove]
lint:     `{detected-lint-cmd}`    [edit] [remove]
build:    `{detected-build-cmd}`   [edit] [remove]
[add custom gate]

== DRY RUN ==
( ) Off (default; commits land)
( ) On (validate flow; no commits, no frontmatter changes, log only)

== PROCEED ==
After answering, the run proceeds unattended through Steps 1–5.
The next user interaction is at Step 3 (showstoppers) if any arise.

( ) Proceed
( ) Edit detected commands / gates first
( ) Abort
```

## Handling `Edit detected commands / gates first`

Issue **one** follow-up `AskUserQuestion` with free-text slots for each editable gate command. Re-issue the primary prompt with the edited values so the user confirms the whole set with the corrections in view. Maximum two round-trips total. Never loop.

## Output capture

After the user's final answer, record a `PREFLIGHT_DECISIONS` object in working memory:

```
PREFLIGHT_DECISIONS = {
  "cluster_subset": "all" | "only: [slug, slug]" | "all-except: [slug, slug]",
  "include_terminal": false,   # default; when true, clusters in terminal Status are eligible for re-attempt
  "session_number": 1,         # computed by scanning analysis-analysis.md for prior `## Part B ... (session N, ...)` headings and picking N+1
  "decisions": {
    "04-auth-rewrite": "answer text",
    ...
  },
  "needs_spec_handling": {
    "02-webgl-harness": "auto-defer" | "spec: <free text>",
    ...
  },
  "branch_strategy": "new-branch" | "current-branch" | "worktree",
  "branch_name": "fix/deep-analysis-2026-04-21",  # derived when relevant; reused if already exists on resumption
  "gates": {
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    ...
  },
  "gate_timeouts": {
    "test": 600,    # seconds; default 600 (10 min) per gate
    "build": 1800,  # 30 min override
    ...
  },
  "test_dir_classification": {
    "tests/unit": {"tsc_checked": true, "notes": ""},
    "tests/api":  {"tsc_checked": false, "notes": "..."},
    ...
  },
  "dry_run": false
}
```

Steps 1–5 read from this object exclusively. No re-detection. No re-parsing.

## Timeouts

If the user does not respond to the primary prompt, exit cleanly with a message: *"No preflight response; exiting without changes."* Do not proceed with defaults — unlike cda's Step 0 confirmation prompt (which has a sane "proceed" default to support overnight runs), here the user has not even authorized the run.

## Common mistakes

- **Asking anything before detecting everything.** Do all detection first; the prompt shows a summary, not live questions.
- **Re-asking a decision mid-run.** Every `needs-decision` cluster's question lives here or nowhere.
- **Silently defaulting a branch on a dirty tree.** If the tree has uncommitted changes AND the user picks `current-branch`, show a warning line in the prompt and require explicit confirmation. Do not auto-stash.
- **Including terminal-state clusters in `all` by default.** Resumption must be safe. Auto-filter terminal-state clusters from the default `all` subset; surface the count so the user knows what was skipped; require explicit `include-terminal: true` to re-attempt.
- **Forgetting to compute `session_number`.** On resumption, the Part B writer needs `N+1`. Scan `analysis-analysis.md` for `^## Part B — Fix coordinator retrospective \(session (\d+)` headings and pick `max(N) + 1`. First run always yields `1`.
- **Recreating an existing branch on resumption.** If `branch_strategy = new-branch` AND the computed `branch_name` already exists, `git checkout` it and fast-forward if possible. Only abort if the branch is in a state incompatible with continued work (e.g., diverged from origin in a way git won't fast-forward).
